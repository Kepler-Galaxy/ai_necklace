import aiohttp
from bs4 import BeautifulSoup

# TODO(yiqi): use async version
def fetch_wechat_article_content(url: str) -> str:
    # async with aiohttp.ClientSession() as session:
    #     async with session.get(url) as response:
    #         if response.status != 200:
    #             raise Exception(f"Failed to fetch article: HTTP {response.status}")
    #         html = await response.text()

    # soup = BeautifulSoup(html, 'html.parser')
    # content = soup.find(id='js_content')
    # if content:
    #     print(f"wechat content is {content.get_text(strip=True)}")
    #     return content.get_text(strip=True)
    # else:
    #     raise Exception("Failed to extract article content")
    
    with aiohttp.ClientSession() as session:
        with session.get(url) as response:
            if response.status != 200:
                raise Exception(f"Failed to fetch article: HTTP {response.status}")
            html = response.text()

    soup = BeautifulSoup(html, 'html.parser')
    content = soup.find(id='js_content')
    if content:
        print(f"wechat content is {content.get_text(strip=True)}")
        return content.get_text(strip=True)
    else:
        raise Exception("Failed to extract article content")