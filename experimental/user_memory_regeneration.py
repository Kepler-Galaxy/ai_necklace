import requests
import time
from loguru import logger

BASE_URL = "https://delicate-elephant-close.ngrok-free.app"
AUTH_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlMtejlfeVhybUotLWFmbFFkdFRpbmhVcVdJVEMxRVVuVUlUVmgwaGs4aHcifQ.eyJzdWIiOiI2NmQxNGNhYTYzMGNlNjQ3MDRkYTgxODgiLCJhdWQiOiI2NmNjMjg4ZmUxZDExYmExNGJlNWE2M2YiLCJzY29wZSI6InByb2ZpbGUgdXNlcm5hbWUgb3BlbmlkIGVtYWlsIGV4dGVybmFsX2lkIGV4dGVuZGVkX2ZpZWxkcyBwaG9uZSB0ZW5hbnRfaWQgcm9sZXMgb2ZmbGluZV9hY2Nlc3MiLCJpYXQiOjE3MjYwNDMyMzYsImV4cCI6MTcyNzI1MjgzNiwianRpIjoiRlRpMkdKdC16aXh4N2xxMGpmeE5ER1l1ZmliWWI2NEZMcFZRaHdXd3JFOCIsImlzcyI6Imh0dHBzOi8va3N0YXIuYXV0aGluZy5jbi9vaWRjIn0.kon7j-8AdLIcXsBXyFovz7Kn7uxaIQTV8i0bgQlnlSU_upd_p3nSYDY3zUaK-GiY2WC1wH0E20dSMKGAR9n1XwU4Ia1IJoos8ZtUnxpHm4rkoaDsfxkB4DzCCe7eUKpTQPGQbDRnQijHJd_8Wk12ijzSb78fqjbRYa77McJrZeWwEY4-2lut5lRlxYu3scYBluzZJlynpIBnHZ5sjKXNANLsBGYjE8pQt3Vb9V8rUjnyDqMkgEHWTTplRPOrSRoPe_Xf76PB8WK3DZa26P4NVstu3o74C4s8frUPB_-hdGOt8-89e0ipyWDD1SgE2Rj2dGfyLwQ_GUIkOfWmXt_W6A"

def get_memories(offset: int = 0, limit: int = 100):
    url = f"{BASE_URL}/v1/memories?offset={offset}&limit={limit}"
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}",
        "Provider": "authing"
    }
    
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        return response.json()
    else:
        logger.error(f"Error fetching memories: {response.status_code}")
        return []

def regenerate_memory(memory_id: str):
    url = f"{BASE_URL}/v1/memories/{memory_id}/reprocess"
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}",
        "Provider": "authing"
    }
    
    response = requests.post(url, headers=headers)
    if response.status_code == 200:
        logger.info(f"Successfully regenerated memory {memory_id}")
    else:
        logger.error(f"Error regenerating memory {memory_id}: {response.status_code}")

def main():
    offset = 0
    limit = 100
    total_regenerated = 0

    while True:
        memories = get_memories(offset, limit)
        
        if not memories:
            break

        for memory in memories:
            if not memory.get('discarded', False):
                regenerate_memory(memory['id'])
                total_regenerated += 1
                time.sleep(10)  # Add a 10-second delay between requests

        offset += limit
        logger.info(f"Processed {offset} memories so far")

    logger.info(f"Finished regenerating {total_regenerated} memories")

if __name__ == "__main__":
    main()