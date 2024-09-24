import os

from pymongo import MongoClient, UpdateOne
from typing import Any, Dict, List, Optional


ID_Field_DICT = {
    "users": "uid"
}

class DocumentSnapshot:
    def __init__(self, document_id: Any, data: Dict[str, Any]):
        self.id = document_id
        self._data = data

    def to_dict(self) -> Dict[str, Any]:
        """返回文档的字典表示。"""
        return self._data

class DocumentReference:
    def __init__(self, db, collection_name: str, document_id: Optional[Any] = None):
        self.db = db
        self.collection_name = collection_name
        self.collection_ref = self.db[self.collection_name]
        self.document_id = document_id

    def collection(self, subcollection_name: str):
        # Simulate subcollections by using a naming convention
        # full_collection_name = f"{self.collection_name}.{self.document_id}.{subcollection_name}"
        print(subcollection_name)
        if self.collection_name == "users":
            return CollectionReference(self.db, subcollection_name, FieldFilter(ID_Field_DICT.get(self.collection_name), "=", self.document_id))
        else:
            return CollectionReference(self.db, subcollection_name)

    def set(self, data: Dict[str, Any], merge: bool = False):
        if merge:
            self.collection_ref.update_one({'_id': self.document_id}, {'$set': data}, upsert=True)
        else:
            data['_id'] = self.document_id
            self.collection_ref.replace_one({'_id': self.document_id}, data, upsert=True)

    def get(self) -> DocumentSnapshot:
        doc_data = self.collection_ref.find_one({'_id': self.document_id})
        if doc_data:
            return DocumentSnapshot(doc_data['_id'], doc_data)
        else:
            return DocumentSnapshot(0, {})

    def delete(self):
        self.collection_ref.delete_one({'_id': self.document_id})

    def update(self, data: Dict[str, Any]):
        self.collection_ref.update_one({'_id': self.document_id}, {'$set': data})


class CollectionReference:
    def __init__(self, db, collection_name: str, *filters):
        self.db = db
        self.collection_name = collection_name
        self.collection = self.db[self.collection_name]
        self._filters = list(filters)

    def document(self, document_id: Optional[Any] = None):
        return DocumentReference(self.db, self.collection_name, document_id)

    def where(self, filter):
        self._filters.append(filter)
        return self

    def stream(self):
        query = {}
        for filter in self._filters:
            query.update(filter.to_query())
        # todo: Change to return a documentSnapshot list @zhihuangliu
        return self.collection.find(query)

    def add(self, data: Dict[str, Any]):
        result = self.collection.insert_one(data)
        return result.inserted_id

    # Additional methods like get(), etc., can be implemented as needed


class WriteBatch:
    def __init__(self, db):
        self.db = db
        self.operations = []

    def set(self, doc_ref: DocumentReference, data: Dict[str, Any], merge: bool = False):
        if merge:
            update = UpdateOne({'_id': doc_ref.document_id}, {'$set': data}, upsert=True)
        else:
            data['_id'] = doc_ref.document_id
            update = UpdateOne({'_id': doc_ref.document_id}, {'$set': data}, upsert=True)
        self.operations.append((doc_ref.collection_name, update))

    def commit(self):
        # Group operations by collection
        collections = {}
        for collection_name, operation in self.operations:
            collections.setdefault(collection_name, []).append(operation)

        # Execute bulk writes for each collection
        for collection_name, ops in collections.items():
            self.db[collection_name].bulk_write(ops)


class FieldFilter:
    def __init__(self, field: str, op: str, value: Any):
        self.field = field
        self.op = op
        self.value = value

    def to_query(self):
        op_map = {
            '==': lambda f, v: {f: v},
            '!=': lambda f, v: {f: {'$ne': v}},
            '>': lambda f, v: {f: {'$gt': v}},
            '>=': lambda f, v: {f: {'$gte': v}},
            '<': lambda f, v: {f: {'$lt': v}},
            '<=': lambda f, v: {f: {'$lte': v}},
            'in': lambda f, v: {f: {'$in': v}},
            'not-in': lambda f, v: {f: {'$nin': v}},
            'array-contains': lambda f, v: {f: v},  # MongoDB automatically matches arrays
            'array-contains-any': lambda f, v: {f: {'$in': v}},
        }
        if self.op in op_map:
            return op_map[self.op](self.field, self.value)
        else:
            raise ValueError(f"Unsupported operator: {self.op}")


# Singleton pattern for the database client
class MongoDBClient:
    _instance = None

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def __init__(self):
        # Initialize the MongoDB client
        self.mongodb_uri = os.getenv("MONGODB_URI")
        self.database = os.getenv("MONGODB_DATABASE")
        print(self.mongodb_uri)
        print(self.database)
        self.client = MongoClient(self.mongodb_uri)
        self.db = self.client[self.database]

    def collection(self, collection_name: str):
        return CollectionReference(self.db, collection_name)

    def batch(self):
        return WriteBatch(self.db)

# Create a global db instance
db = MongoDBClient.instance()

