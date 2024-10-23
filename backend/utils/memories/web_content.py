import aiohttp
from bs4 import BeautifulSoup
import re
from readability import Document
import html2text
from urllib.parse import urlparse
from raw_data.little_red_book import extract_little_red_book_content
from raw_data.web_content_response import WebContentResponseV2, WeChatContentResponse, GeneralWebContentResponse

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
    

async def extract_general_web_content(url: str) -> WebContentResponseV2:
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers={'User-Agent': 'Mozilla/5.0'}) as response:
                response.raise_for_status()
                content = await response.content
        
        doc = Document(content)
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
        return WebContentResponseV2(
            response=GeneralWebContentResponse(
                success=True,
                url=url,
                title=doc.title(),
                content_type="general",
                main_content=structured_content
            ),
            raw_data={}
        )
    except Exception as e:
        return WebContentResponseV2(
            response=GeneralWebContentResponse(
                success=False,
                url=url,
                title="",
                content_type="general",
                main_content="fetch article content failed, maybe the url is not valid or permission denied"
            ),
            raw_data={}
        )
    
async def extract_wechat_content(url: str) -> WebContentResponseV2:
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers={'User-Agent': 'Mozilla/5.0'}) as response:
                response.raise_for_status()
                content = await response.read()

        soup = BeautifulSoup(content, 'html.parser')
        
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
        
        return WebContentResponseV2(
            response=WeChatContentResponse(
                success=True,
                url=url,
                title=title,
                content_type="wechat",
                main_content=main_content
            ),
            raw_data={}
        )
    except Exception as e:
        return WebContentResponseV2(
            response=WeChatContentResponse(
                success=False,
                url=url,
                title="",
                content_type="wechat",
                main_content=f"Failed to extract WeChat content: {str(e)}"
            ),
            raw_data={}
        )

async def extract_web_content(url: str) -> WebContentResponseV2:
    parsed_url = urlparse(url)
    
    if parsed_url.netloc == "mp.weixin.qq.com":
        print("Extracting WeChat content...")
        return await extract_wechat_content(url)
    elif parsed_url.netloc in ["www.xiaohongshu.com", "xiaohongshu.com", "xhslink.com"]:
        print("Extracting Little Red Book content...")
        return await extract_little_red_book_content(url)
    else:
        print("Extracting general web content...")
        return await extract_general_web_content(url)
