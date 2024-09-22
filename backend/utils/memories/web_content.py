import requests
from bs4 import BeautifulSoup
import re
from pydantic import BaseModel
from readability import Document
import html2text
from urllib.parse import urlparse

class WebContentResponse(BaseModel):
    success: bool
    title: str
    main_content: str
    url: str

class CustomHTML2Text(html2text.HTML2Text):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.links_seen = set()

    def handle_tag(self, tag, attrs, start):
        if tag == 'a' and start:
            href = dict(attrs).get('href')
            if href:
                if href not in self.links_seen:
                    self.links_seen.add(href)
                    return super().handle_tag(tag, attrs, start)
                else:
                    # For repeated links, just output the text content
                    return self.handle_data
        return super().handle_tag(tag, attrs, start)
    

def extract_general_web_content(url: str) -> WebContentResponse:
    try:
        response = requests.get(url)
        response.raise_for_status()
        
        doc = Document(response.content)
        main_content_html = doc.summary()
        h = CustomHTML2Text()
        h.ignore_links = False
        h.ignore_images = False
        h.ignore_emphasis = False
        h.body_width = 0  # Disable line wrapping
        structured_content = h.handle(main_content_html)

        # Input: "Check out [this link](http://example.com) for more info."
        # Output: "Check out this link for more info."
        structured_content = re.sub(r'\[(.*?)\]\(.*?\)', r'\1', structured_content)
        return WebContentResponse(  
            success=True,
            title=doc.title(),
            main_content=structured_content,
            url=url
        )
    except Exception as e:
        return WebContentResponse(
            success=False,
            title="",
            main_content="fetch article content failed, maybe the url is not valid or permission denied",
            url=url
        )
    
def extract_wechat_content(url: str) -> WebContentResponse:
    try:
        headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()
        
        soup = BeautifulSoup(response.content, 'html.parser')
        
        title = soup.find('h1', class_='rich_media_title').text.strip()
        
        content_div = soup.find('div', class_='rich_media_content')
        if content_div:
            content_html = str(content_div)
            h = CustomHTML2Text()
            h.ignore_links = False
            h.ignore_images = False
            h.ignore_emphasis = False
            h.body_width = 0  # Disable line wrapping
            main_content = h.handle(content_html)
            
            # Clean up excessive newlines and spaces
            main_content = re.sub(r'\n{3,}', '\n\n', main_content)
            main_content = re.sub(r' {2,}', ' ', main_content)
        else:
            main_content = "Content extraction failed."
        
        return WebContentResponse(success=True, title=title, main_content=main_content, url=url)
    except Exception as e:
        return WebContentResponse(success=False, title="", main_content=f"Failed to extract WeChat content: {str(e)}", url=url)

def extract_web_content(url: str) -> WebContentResponse:
    parsed_url = urlparse(url)
    if parsed_url.netloc == "mp.weixin.qq.com":
        print("Extracting WeChat content...")
        return extract_wechat_content(url)
    else:
        print("Extracting general web content...")
        return extract_general_web_content(url)
  