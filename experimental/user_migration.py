import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore

# Initialize Firebase Admin SDK
# cred = credentials.Certificate("../backend/credentials.json")
# firebase_admin.initialize_app(cred)
firebase_admin.initialize_app()

# Get Firestore client
db = firestore.client()

def copy_collection(source_ref, target_ref, collection_names):
    for collection_name in collection_names:
        # Get reference to source collection
        source_collection_ref = source_ref.collection(collection_name)
        
        # Get all documents in the source collection
        docs = source_collection_ref.get()
        
        # Iterate through each document and copy it to the target collection
        for doc in docs:
            # Get the data and ID of the source document
            doc_data = doc.to_dict()
            doc_id = doc.id
            
            # Create a new document in the target collection with the same ID and data
            target_ref.collection(collection_name).document(doc_id).set(doc_data)
            
            print(f"Copied document {doc_id} in collection {collection_name}")

        print(f"Finished copying collection {collection_name}")

# Usage
source_ref = db.collection('users').document('fn0v3YCeCkY36yuoC6Cbhjpf2BE2')
target_ref = db.collection('users').document('66d14caa630ce64704da8188')
collection_names = ["memories", "facts"]

copy_collection(source_ref, target_ref, collection_names)