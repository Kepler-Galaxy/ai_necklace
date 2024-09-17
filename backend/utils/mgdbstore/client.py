from pymongo import MongoClient, UpdateOne
from typing import Any, Dict, List, Optional


class DocumentReference:
    def __init__(self, db, collection_name: str, document_id: Optional[Any] = None):
        self.db = db
        self.collection_name = collection_name
        self.collection = self.db[self.collection_name]
        self.document_id = document_id

    def collection(self, subcollection_name: str):
        # Simulate subcollections by using a naming convention
        full_collection_name = f"{self.collection_name}.{self.document_id}.{subcollection_name}"
        return CollectionReference(self.db, full_collection_name)

    def set(self, data: Dict[str, Any], merge: bool = False):
        if merge:
            self.collection.update_one({'_id': self.document_id}, {'$set': data}, upsert=True)
        else:
            data['_id'] = self.document_id
            self.collection.replace_one({'_id': self.document_id}, data, upsert=True)

    def get(self):
        return self.collection.find_one({'_id': self.document_id})

    def delete(self):
        self.collection.delete_one({'_id': self.document_id})


class CollectionReference:
    def __init__(self, db, collection_name: str):
        self.db = db
        self.collection_name = collection_name
        self.collection = self.db[self.collection_name]
        self._filters = []

    def document(self, document_id: Optional[Any] = None):
        return DocumentReference(self.db, self.collection_name, document_id)

    def where(self, filter):
        self._filters.append(filter)
        return self

    def stream(self):
        query = {}
        for filter in self._filters:
            query.update(filter.to_query())
        return self.collection.find(query)

    # Additional methods like get(), add(), etc., can be implemented as needed


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
        self.client = MongoClient('mongodb://localhost:27017/')
        self.db = self.client['your_database_name']  # Replace with your database name

    def collection(self, collection_name: str):
        return CollectionReference(self.db, collection_name)

    def batch(self):
        return WriteBatch(self.db)

# Create a global db instance
db = MongoDBClient.instance()

