import os
import json

from asgiref.timeout import timeout
from pymongo import MongoClient
from dotenv import load_dotenv
load_dotenv()

import firebase_admin
from google.cloud import firestore

from fastapi import FastAPI, BackgroundTasks
from utils.mgdbstore import client
from database._client import db as fdb

if os.environ.get('SERVICE_ACCOUNT_JSON'):
    service_account_info = json.loads(os.environ["SERVICE_ACCOUNT_JSON"])
    credentials = firebase_admin.credentials.Certificate(service_account_info)
    firebase_admin.initialize_app(credentials)
else:
    print('initializing firebase without credentials')
    firebase_admin.initialize_app()

def test_stream():
    users_ref = (
        client.db.collection("users").order_by('created_at', direction=firestore.Query.DESCENDING).limit(1).offset(1)
    )

    for doc in users_ref.stream():
        print(doc.id, doc.to_dict())

def database_migration():
    for user in fdb.collection("users").stream(timeout=3600):
        print(user.id, user.to_dict())
        user_dict = user.to_dict()
        user_dict["id"] = user.id
        client.db.collection("users").document(user.id).set(user.to_dict())
        for memory in fdb.collection("users").document(user.id).collection("memories").stream(timeout=3600):
            memory_dict = memory.to_dict()
            memory_dict["uid"] = user.id
            client.db.collection("memories").document(memory.id).set(memory_dict)
            # fdb.collection("users").document(user.id).collection("memories").document(memory.id).update(memory_dict)

        for fact in fdb.collection("users").document(user.id).collection("facts").stream(timeout=3600):
            fact_dict = fact.to_dict()
            fact_dict["uid"] = user.id
            client.db.collection("facts").document(fact.id).set(fact_dict)
            # fdb.collection("users").document(user.id).collection("facts").document(fact.id).update(fact_dict)

        for diary in fdb.collection("users").document(user.id).collection("diaries").stream(timeout=3600):
            diary_dict = diary.to_dict()
            diary_dict["uid"] = user.id

            client.db.collection("diaries").document(diary.id).set(diary_dict)
            # fdb.collection("users").document(user.id).collection("diaries").document(diary.id).update(diary_dict)

        for message in fdb.collection("users").document(user.id).collection("messages").stream(timeout=3600):
            message_dict = message.to_dict()
            message_dict["uid"] = user.id
            client.db.collection("messages").document(message.id).set(message_dict)
            # fdb.collection("users").document(user.id).collection("messages").document(message.id).update(message_dict)

        for processing_memory in fdb.collection("users").document(user.id).collection("processing_memories").stream(timeout=3600):
            processing_memory_dict = processing_memory.to_dict()
            processing_memory_dict["uid"] = user.id
            client.db.collection("processing_memories").document(processing_memory.id).set(processing_memory_dict)
            # fdb.collection("users").document(user.id).collection("processing_memories").document(processing_memory.id).update(processing_memory_dict)


if __name__ == "__main__":
    test_stream()


