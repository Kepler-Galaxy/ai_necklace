import aiohttp
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
from typing import List
from urllib.parse import urlparse

from raw_data.web_content_response import WebContentResponseV2, LittleRedBookContentResponse
from io import BytesIO
from PIL import Image
import base64
from loguru import logger

async def extract_little_red_book_content(url: str) -> WebContentResponseV2:
    try:
        async with aiohttp.ClientSession() as session:
            async with session.get(url, headers={'User-Agent': 'Mozilla/5.0'}) as response:
                response.raise_for_status()
                content = await response.text()

        soup = BeautifulSoup(content, 'html.parser')
        
        script_tag = soup.find('script', string=lambda t: t and '__INITIAL_STATE__' in t)
        if not script_tag:
            raise ValueError("Could not find JSON data in the HTML content")
        
        match = re.search(r'window\.__INITIAL_STATE__=(.*?)</script>', str(script_tag), re.DOTALL)
        if not match:
            raise ValueError("JSON data extraction regex failed")
        
        json_text = match.group(1).strip()
        json_text = re.sub(r'undefined', 'null', json_text)
        json_text = re.sub(r',\s*}', '}', json_text)
        json_text = re.sub(r',\s*]', ']', json_text)
        
        try:
            data = json.loads(json_text)
        except json.JSONDecodeError as e:
            raise ValueError(f"Failed to parse JSON data: {str(e)}")
        
        if 'note' not in data or 'noteDetailMap' not in data['note']:
            raise KeyError("Missing 'noteDetailMap' in JSON data")
        
        note_detail_map = data['note']['noteDetailMap']
        if not note_detail_map:
            raise ValueError("'noteDetailMap' is empty")
        
        note_id = data['note']['firstNoteId']
        note_data = note_detail_map[note_id]['note']
        
        required_fields = ['title', 'user', 'time', 'lastUpdateTime', 'desc', 'imageList', 'tagList']
        for field in required_fields:
            if field not in note_data:
                raise KeyError(f"Missing '{field}' in note data")
        
        image_urls = [img['urlDefault'] for img in note_data.get('imageList', []) if 'urlDefault' in img]
        image_base64_pngs = await extract_png_from_urls(image_urls)
        
        little_red_book_response = LittleRedBookContentResponse(
            success=True,
            url=url,
            title=note_data.get('title', ''),
            content_type="little_red_book",
            author=note_data['user'].get('nickname', ''),
            uid=note_data['user'].get('userId', ''),
            note_id=note_id,
            time=datetime.fromtimestamp(note_data.get('time', 0) / 1000),
            last_update_time=datetime.fromtimestamp(note_data.get('lastUpdateTime', 0) / 1000),
            ip_location=note_data.get('ipLocation', ''),
            description=note_data.get('desc', ''),
            tags=[tag.get('name', '') for tag in note_data.get('tagList', [])],
            text_content=note_data.get('desc', ''),
            image_urls=image_urls,
            image_base64_pngs=image_base64_pngs
        )
        
        return WebContentResponseV2(
            response=little_red_book_response,
            raw_data={},
            version=2
        )
    except Exception as e:
        logger.error(f"Failed to extract Xiaohongshu content: {str(e)}")
        return WebContentResponseV2(
            response=LittleRedBookContentResponse(
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
            ),
            raw_data={},
            version=2
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
                logger.error(f"Failed to extract PNG from {url}: {str(e)}")
    
    return base64_pngs
