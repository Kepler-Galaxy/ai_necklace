import subprocess
from datetime import datetime, timedelta
import time

def generate_diary(start_date, end_date, auth_token):
    start_time = start_date.replace(hour=0, minute=20, second=0, microsecond=0)
    end_time = start_date.replace(hour=23, minute=40, second=0, microsecond=0)
    
    start_at_utc = start_time.isoformat() + "Z"
    end_at_utc = end_time.isoformat() + "Z"
    
    curl_command = [
        'curl', '-X', 'POST',
        '-H', f"Authorization: Bearer {auth_token}",
        '-H', "Provider: authing",
        f"https://equal-magnetic-pheasant.ngrok-free.app/v1/diaries/?start_at_utc={start_at_utc}&end_at_utc={end_at_utc}"
    ]
    
    try:
        result = subprocess.run(curl_command, capture_output=True, text=True, check=True)
        print(f"Diary generated for {start_date.date()}: {result.stdout}")
    except subprocess.CalledProcessError as e:
        print(f"Error generating diary for {start_date.date()}: {e.stderr}")

def main():
    auth_token = "eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IlMtejlfeVhybUotLWFmbFFkdFRpbmhVcVdJVEMxRVVuVUlUVmgwaGs4aHcifQ.eyJzdWIiOiI2NmQxNGNhYTYzMGNlNjQ3MDRkYTgxODgiLCJhdWQiOiI2NmNjMjg4ZmUxZDExYmExNGJlNWE2M2YiLCJzY29wZSI6InByb2ZpbGUgdXNlcm5hbWUgb3BlbmlkIGVtYWlsIGV4dGVybmFsX2lkIGV4dGVuZGVkX2ZpZWxkcyBwaG9uZSB0ZW5hbnRfaWQgcm9sZXMgb2ZmbGluZV9hY2Nlc3MiLCJpYXQiOjE3MjYwNDMyMzYsImV4cCI6MTcyNzI1MjgzNiwianRpIjoiRlRpMkdKdC16aXh4N2xxMGpmeE5ER1l1ZmliWWI2NEZMcFZRaHdXd3JFOCIsImlzcyI6Imh0dHBzOi8va3N0YXIuYXV0aGluZy5jbi9vaWRjIn0.kon7j-8AdLIcXsBXyFovz7Kn7uxaIQTV8i0bgQlnlSU_upd_p3nSYDY3zUaK-GiY2WC1wH0E20dSMKGAR9n1XwU4Ia1IJoos8ZtUnxpHm4rkoaDsfxkB4DzCCe7eUKpTQPGQbDRnQijHJd_8Wk12ijzSb78fqjbRYa77McJrZeWwEY4-2lut5lRlxYu3scYBluzZJlynpIBnHZ5sjKXNANLsBGYjE8pQt3Vb9V8rUjnyDqMkgEHWTTplRPOrSRoPe_Xf76PB8WK3DZa26P4NVstu3o74C4s8frUPB_-hdGOt8-89e0ipyWDD1SgE2Rj2dGfyLwQ_GUIkOfWmXt_W6A"
    
    start_date = datetime(2024, 7, 10)
    end_date = datetime(2024, 9, 11)
    
    current_date = start_date
    while current_date <= end_date:
        generate_diary(current_date, current_date, auth_token)
        current_date += timedelta(days=1)
        time.sleep(10)  # Add a 10-second delay between requests to avoid overwhelming the server

if __name__ == "__main__":
    main()