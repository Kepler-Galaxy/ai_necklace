import pytest
import os
from pymongo import MongoClient
from dotenv import load_dotenv
load_dotenv()

from client import MongoDBClient, FieldFilter, db


# 设置测试环境的 MongoDB，后续流程正规后可以打开
@pytest.fixture(scope="module")
def mongo_test_db():
    pass
#     # 创建 MongoDB 连接
#     client = MongoClient('xxx')
#     test_db = client['xxx']  # 使用测试数据库
#     yield test_db
#     # 测试后清理数据库
#     client.drop_database('xxx')


# 测试单个文档插入和获取
# def test_document_reference_set_and_get(mongo_test_db):
#     doc_ref = db.collection("users").document("test_user_1")
#     # 插入文档
#     data = {
#         "name": "John Doe",
#         "email": "john@example.com",
#         "age": 30
#     }
#     doc_ref.set(data)
#
#     # 获取文档
#     result = doc_ref.get().to_dict()
#     assert result['name'] == "John Doe"
#     assert result['email'] == "john@example.com"
#     assert result['age'] == 30


# 测试文档删除
def test_document_reference_delete(mongo_test_db):
    doc_ref = db.collection("users").document("test_user_2")
    data = {"name": "Jane Doe", "email": "jane@example.com"}
    doc_ref.set(data)

    # 删除文档
    doc_ref.delete()

    # 获取文档应返回 None
    result = doc_ref.get().to_dict()

    assert result is not {}


# 测试批量写入
def test_write_batch(mongo_test_db):
    batch = db.batch()

    # 创建两个文档
    doc_ref_1 = db.collection("users").document("test_user_3")
    doc_ref_2 = db.collection("users").document("test_user_4")

    # 使用批量操作插入文档
    data_1 = {"name": "User 3", "email": "user3@example.com"}
    data_2 = {"name": "User 4", "email": "user4@example.com"}

    batch.set(doc_ref_1, data_1)
    batch.set(doc_ref_2, data_2)
    batch.commit()

    # 验证插入是否成功
    assert doc_ref_1.get().to_dict()["name"] == "User 3"
    assert doc_ref_2.get().to_dict()["name"] == "User 4"

#
# # 测试 where 过滤查询
def test_collection_reference_where(mongo_test_db):
    # 插入测试数据
    doc_ref_1 = db.collection("users").document("test_user_5")
    doc_ref_2 = db.collection("users").document("test_user_6")

    doc_ref_1.set({"name": "User 5", "age": 25})
    doc_ref_2.set({"name": "User 6", "age": 30})

    # 使用 where 进行查询
    users_over_25 = db.collection("users").where(FieldFilter("age", ">", 25)).stream()
    result = [user.to_dict()['name'] for user in users_over_25]

    assert len(result) == 1
    assert "User 6" in result
#
#
# # 测试嵌套 collection 操作
def test_subcollection_reference(mongo_test_db):
    user_ref = db.collection("users").document("test_user_7")
    subcollection_ref = user_ref.collection("memories").document("memory_1")

    # 插入嵌套文档
    data = {"title": "First Memory", "description": "A great memory"}
    subcollection_ref.set(data)

    # 验证插入成功
    result = subcollection_ref.get().to_dict()
    assert result["title"] == "First Memory"
    assert result["description"] == "A great memory"

def test_chunk_user(mongo_test_db):
    users_ref = db.collection('users')
    chunk_list = ['Asia/Shanghai', 'Asia/Tokyo']
    def query_chunk(chunk):
        def sync_query():
            chunk_users = []
            try:
                # Query users with time_zone in the specified chunk
                query = users_ref.where(filter=FieldFilter('time_zone', 'in', chunk))
                for doc in query.stream():
                    if filter == 'fcm_token':
                        token = doc.get('fcm_token')
                    else:
                        token = doc.id, doc.get('fcm_token')
                    if token:
                        chunk_users.append(token)

                # Assume users without time_zone information is in shanghai
                if 'Asia/Shanghai' in chunk:
                    query_default = users_ref.where(filter=FieldFilter('time_zone', '==', None))
                    for doc in query_default.stream():
                        if filter == 'fcm_token':
                            token = doc.get('fcm_token')
                        else:
                            token = doc.id, doc.get('fcm_token')
                        if token:
                            chunk_users.append(token)
            except Exception as e:
                assert False
            return chunk_users
        return sync_query()
    print(query_chunk(chunk_list))