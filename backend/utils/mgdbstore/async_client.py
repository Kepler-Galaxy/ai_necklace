import os
import motor.motor_asyncio
from typing import Any, Dict, List, Optional

from utils.mgdbstore.client import DocumentSnapshot, FieldFilter

ASCENDING = "ASCENDING"
DESCENDING = "DESCENDING"

ID_Field_DICT = {
    "users": "uid"
}


class DocumentReference:
    def __init__(self, db, collection_name: str, document_id: Optional[Any] = None):
        self.db = db
        self.collection_name = collection_name
        self.collection_ref = self.db[self.collection_name]
        self.document_id = document_id

    def collection(self, subcollection_name: str):
        """获取子集合的引用"""
        if self.collection_name == "users":
            return CollectionReference(self.db, subcollection_name, FieldFilter(ID_Field_DICT.get(self.collection_name), "=", self.document_id))
        else:
            return CollectionReference(self.db, subcollection_name)

    async def set(self, data: Dict[str, Any], merge: bool = False):
        """异步设置文档"""
        if merge:
            await self.collection_ref.update_one({'_id': self.document_id}, {'$set': data}, upsert=True)
        else:
            data['_id'] = self.document_id
            await self.collection_ref.replace_one({'_id': self.document_id}, data, upsert=True)

    async def get(self) -> DocumentSnapshot:
        """异步获取文档"""
        doc_data = await self.collection_ref.find_one({'_id': self.document_id})
        if doc_data:
            return DocumentSnapshot(doc_data['_id'], doc_data)
        else:
            return DocumentSnapshot(0, {})

    async def delete(self):
        """异步删除文档"""
        await self.collection_ref.delete_one({'_id': self.document_id})

    async def update(self, data: Dict[str, Any]):
        """异步更新文档"""
        await self.collection_ref.update_one({'_id': self.document_id}, {'$set': data})


class CollectionReference:
    def __init__(self, db, collection_name: str, *filters):
        self.db = db
        self.collection_name = collection_name
        self.collection = self.db[self.collection_name]
        self._filters = list(filters)
        self._sort = None
        self._limit = None
        self._offset = None

    def document(self, document_id: Optional[Any] = None):
        return DocumentReference(self.db, self.collection_name, document_id)

    def where(self, filter):
        self._filters.append(filter)
        return self

    def order_by(self, field: str, direction: str = "ASCENDING"):
        """按指定字段排序，默认升序"""
        if direction == ASCENDING:
            self._sort = (field, 1)
        elif direction == DESCENDING:
            self._sort = (field, -1)
        else:
            raise ValueError(f"Invalid sort direction: {direction}")
        return self

    def limit(self, limit: int):
        """限制返回文档的数量"""
        self._limit = limit
        return self

    def offset(self, offset: int):
        """跳过指定数量的文档"""
        self._offset = offset
        return self

    async def stream(self):
        """异步执行查询并返回结果"""
        query = {}
        for filter in self._filters:
            query.update(filter.to_query())

        cursor = self.collection.find(query)

        if self._sort:
            cursor = cursor.sort([self._sort])

        if self._limit is not None:
            cursor = cursor.limit(self._limit)

        if self._offset is not None:
            cursor = cursor.skip(self._offset)

        async for doc in cursor:
            yield DocumentSnapshot(doc['_id'], doc)

    async def add(self, data: Dict[str, Any]):
        """异步添加文档"""
        result = await self.collection.insert_one(data)
        return result.inserted_id


class WriteBatch:
    def __init__(self, db):
        self.db = db
        self.operations = []

    def set(self, doc_ref: DocumentReference, data: Dict[str, Any], merge: bool = False):
        if merge:
            update = motor.motor_asyncio.AsyncIOMotorClient.UpdateOne({'_id': doc_ref.document_id}, {'$set': data}, upsert=True)
        else:
            data['_id'] = doc_ref.document_id
            update = motor.motor_asyncio.AsyncIOMotorClient.UpdateOne({'_id': doc_ref.document_id}, {'$set': data}, upsert=True)
        self.operations.append((doc_ref.collection_name, update))

    def update(self, doc_ref, update_data):
        """添加 update 操作到批量中"""
        operation = motor.motor_asyncio.AsyncIOMotorClient.UpdateOne(
            {'_id': doc_ref.document_id},  # 依据文档 ID 更新
            {'$set': update_data}          # 更新的数据
        )
        self.operations.append((doc_ref.collection_name, operation))

    async def commit(self):
        """异步提交批量操作"""
        collections = {}
        for collection_name, operation in self.operations:
            collections.setdefault(collection_name, []).append(operation)

        for collection_name, ops in collections.items():
            collection = self.db[collection_name]
            await collection.bulk_write(ops)


class AsyncClient:

    _instance = None

    def __new__(cls, *args, **kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        # 如果 _instance 已经存在，直接返回这个实例
        return cls._instance

    def __init__(self):
        if not hasattr(self, '_initialized'):
            self.mongodb_uri = os.getenv("MONGODB_URI")
            self.database = os.getenv("MONGODB_DATABASE")
            self.client = motor.motor_asyncio.AsyncIOMotorClient(self.mongodb_uri)
            self.db = self.client[self.database]
            self._initialized = True

    def collection(self, collection_name: str):
        return CollectionReference(self.db, collection_name)

    def batch(self):
        return WriteBatch(self.db)

    async def get_all(self, doc_refs: list):
        """根据文档引用批量获取文档"""
        for doc_ref in doc_refs:
            doc_data = await doc_ref.get()
            if doc_data is not None:
                yield DocumentSnapshot(doc_ref.document_id, doc_data.to_dict())
            else:
                yield DocumentSnapshot(doc_ref.document_id)
