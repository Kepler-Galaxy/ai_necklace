import aiohttp
from bs4 import BeautifulSoup
import json
import re
from datetime import datetime
from typing import List, Tuple
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
        image_base64_jpegs, low_res_image_base64_jpegs = await extract_original_and_low_res_jpegs_from_urls(image_urls)
        
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
            image_base64_jpegs=image_base64_jpegs,
            low_res_image_base64_jpegs=low_res_image_base64_jpegs
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
                image_base64_jpegs=[],
                low_res_image_base64_jpegs=[]
            ),
            raw_data={},
            version=2
        )

async def extract_original_and_low_res_jpegs_from_urls(image_urls: List[str]) -> Tuple[List[str], List[str]]:
    original_base64_jpegs = []
    low_res_base64_jpegs = []
    async with aiohttp.ClientSession() as session:
        for url in image_urls:
            try:
                async with session.get(url) as response:
                    response.raise_for_status()
                    content = await response.read()
                
                img = Image.open(BytesIO(content))
                img = img.convert('RGB')
                
                original_buffered = BytesIO()
                img.save(original_buffered, format="JPEG", quality=85)
                original_img_str = base64.b64encode(original_buffered.getvalue()).decode()
                original_base64_jpegs.append(original_img_str)
                
                if img.width > img.height:
                    new_width = 512
                    new_height = int(512 * img.height / img.width)
                else:
                    new_height = 512
                    new_width = int(512 * img.width / img.height)
                low_res_img = img.resize((new_width, new_height), Image.LANCZOS)
                
                low_res_buffered = BytesIO()
                low_res_img.save(low_res_buffered, format="JPEG", quality=85)
                low_res_img_str = base64.b64encode(low_res_buffered.getvalue()).decode()
                low_res_base64_jpegs.append(low_res_img_str)
                
            except Exception as e:
                logger.error(f"Failed to extract JPEG from {url}: {str(e)}, skipping image")
    
    return original_base64_jpegs, low_res_base64_jpegs
