import requests
from bs4 import BeautifulSoup

def fetch_wechat_article_content(url: str) -> str:
    response = requests.get(url)
    if response.status_code != 200:
        raise Exception(f"Failed to fetch article: HTTP {response.status_code}")
    
    html = response.text
    soup = BeautifulSoup(html, 'html.parser')
    content = soup.find(id='js_content')
    
    if content:
        print(f"wechat content is {content.get_text(strip=True)}")
        return content.get_text(strip=True)
    else:
        raise Exception("Failed to extract article content")