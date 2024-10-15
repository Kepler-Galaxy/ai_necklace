import aiohttp
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
from typing import List
from urllib.parse import urlparse

from raw_data.web_content_response import LittleRedBookContentResponse
from io import BytesIO
from PIL import Image
import base64

async def extract_little_red_book_content(url: str) -> LittleRedBookContentResponse:
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers={'User-Agent': 'Mozilla/5.0'}) as response:
                response.raise_for_status()
                content = await response.text()

        soup = BeautifulSoup(content, 'html.parser')
        
        script_tag = soup.find('script', string=lambda t: t and '__INITIAL_STATE__' in t)
        if not script_tag:
            raise ValueError("Could not find JSON data in the HTML content")
        
        json_text = re.search(r'window\.__INITIAL_STATE__=(.*?)</script>', str(script_tag), re.DOTALL).group(1)
        data = json.loads(json_text)
        
        note_id = next(iter(data['note']['noteDetailMap']))
        note_data = data['note']['noteDetailMap'][note_id]['note']
        
        image_urls = [img['urlDefault'] for img in note_data.get('imageList', [])]
        image_base64_pngs = await extract_png_from_urls(image_urls)
        
        return LittleRedBookContentResponse(
            success=True,
            url=url,
            title=note_data.get('title', ''),
            content_type="little_red_book",
            author=note_data['user']['nickname'],
            uid=note_data['user']['userId'],
            note_id=note_id,
            time=datetime.fromtimestamp(note_data.get('time', 0) / 1000),
            last_update_time=datetime.fromtimestamp(note_data.get('lastUpdateTime', 0) / 1000),
            ip_location=note_data.get('ipLocation', ''),
            description=note_data.get('desc', ''),
            tags=[tag['name'] for tag in note_data.get('tagList', [])],
            text_content=note_data.get('desc', ''),
            image_urls=image_urls,
            image_base64_pngs=image_base64_pngs
        )
    except Exception as e:
        return LittleRedBookContentResponse(
            success=False,
            url=url,
            title="",
            content_type="little_red_book",
            author="",
            uid="",
            note_id="",
            time=datetime.utcnow(),
            last_update_time=datetime.utcnow(),
            ip_location="",
            description="",
            tags=[],
            text_content=f"Failed to extract Xiaohongshu content: {str(e)}",
            image_urls=[],
            image_base64_pngs=[]
        )

async def extract_png_from_urls(image_urls: List[str]) -> List[str]:
    base64_pngs = []
    async with aiohttp.ClientSession() as session:
        for url in image_urls:
            try:
                async with session.get(url) as response:
                    response.raise_for_status()
                    content = await response.read()
                
                img = Image.open(BytesIO(content))
                img = img.convert('RGB')
                buffered = BytesIO()
                img.save(buffered, format="PNG")
                img_str = base64.b64encode(buffered.getvalue()).decode()
                base64_pngs.append(img_str)
            except Exception as e:
                print(f"Failed to extract PNG from {url}: {str(e)}")
    
    return base64_pngs
