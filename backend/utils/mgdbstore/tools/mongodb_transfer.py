from pymongo import MongoClient

# 连接到源数据库和目标数据库
source_client = MongoClient("mongodb+srv://<user>:<password>@dev-star.ohirf.mongodb.net/?retryWrites=true&w=majority&appName=dev-star")
target_client = MongoClient("mongodb+srv://<user>:<password>@seoul.4widi.mongodb.net/?retryWrites=true&w=majority&appName=Seoul")

source_db = source_client["dev-star"]
target_db = target_client["prod-foxxy"]


def migrate_data():
    # 获取源数据库中的所有集合
    collections = source_db.list_collection_names()

    for collection_name in collections:
        source_collection = source_db[collection_name]
        target_collection = target_db[collection_name]

        print(f"Migrating collection: {collection_name}")

        # 查询源数据库中的数据
        cursor = source_collection.find()  # 获取所有文档，如果只迁移部分数据可以添加条件

        # 批量插入到目标数据库
        batch_size = 1000  # 每次批量插入的大小
        buffer = []

        for doc in cursor:
            # 清理 '_id' 字段，防止冲突
            buffer.append(doc)

            # 当缓冲区达到批量大小时插入数据到目标数据库
            if len(buffer) == batch_size:
                target_collection.insert_many(buffer)
                buffer = []

        # 插入剩余的文档
        if buffer:
            target_collection.insert_many(buffer)

        print(f"Migration of {collection_name} completed.")

if __name__ == "__main__":
    migrate_data()
