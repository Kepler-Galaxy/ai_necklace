import requests
import json

# Constants
API_BASE_URL = "https://equal-magnetic-pheasant.ngrok-free.app"
AUTH_TOKEN = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlMtejlfeVhybUotLWFmbFFkdFRpbmhVcVdJVEMxRVVuVUlUVmgwaGs4aHcifQ.eyJzdWIiOiI2NmQxNGNhYTYzMGNlNjQ3MDRkYTgxODgiLCJhdWQiOiI2NmNjMjg4ZmUxZDExYmExNGJlNWE2M2YiLCJzY29wZSI6InByb2ZpbGUgdXNlcm5hbWUgb3BlbmlkIGVtYWlsIGV4dGVybmFsX2lkIGV4dGVuZGVkX2ZpZWxkcyBwaG9uZSB0ZW5hbnRfaWQgcm9sZXMgb2ZmbGluZV9hY2Nlc3MiLCJpYXQiOjE3MjYwNDMyMzYsImV4cCI6MTcyNzI1MjgzNiwianRpIjoiRlRpMkdKdC16aXh4N2xxMGpmeE5ER1l1ZmliWWI2NEZMcFZRaHdXd3JFOCIsImlzcyI6Imh0dHBzOi8va3N0YXIuYXV0aGluZy5jbi9vaWRjIn0.kon7j-8AdLIcXsBXyFovz7Kn7uxaIQTV8i0bgQlnlSU_upd_p3nSYDY3zUaK-GiY2WC1wH0E20dSMKGAR9n1XwU4Ia1IJoos8ZtUnxpHm4rkoaDsfxkB4DzCCe7eUKpTQPGQbDRnQijHJd_8Wk12ijzSb78fqjbRYa77McJrZeWwEY4-2lut5lRlxYu3scYBluzZJlynpIBnHZ5sjKXNANLsBGYjE8pQt3Vb9V8rUjnyDqMkgEHWTTplRPOrSRoPe_Xf76PB8WK3DZa26P4NVstu3o74C4s8frUPB_-hdGOt8-89e0ipyWDD1SgE2Rj2dGfyLwQ_GUIkOfWmXt_W6A"

def get_memories(limit=10000, offset=0):
    url = f"{API_BASE_URL}/v1/memories"
    headers = {
        "Authorization": f"Bearer {AUTH_TOKEN}",
        "Provider": "authing"
    }
    params = {
        "limit": limit,
        "offset": offset
    }
    
    response = requests.get(url, headers=headers, params=params)
    
    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error fetching memories: {response.status_code}")
        return None

def main():
    memories = get_memories()
    
    if memories:
        valid_geolocation_ids = []
        
        for memory in memories:
            if memory.get('geolocation'):
                valid_geolocation_ids.append(memory['id'])
        
        print("Memory IDs with valid geolocation:")
        for memory_id in valid_geolocation_ids:
            print(memory_id)
        
        print(f"\nTotal memories with valid geolocation: {len(valid_geolocation_ids)}")
    else:
        print("No memories found or error occurred.")

if __name__ == "__main__":
    main()