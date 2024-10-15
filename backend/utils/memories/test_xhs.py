import requests
from bs4 import BeautifulSoup
import re
from pydantic import BaseModel
from readability import Document
import html2text
from urllib.parse import urlparse
import base64
import io
from PIL import Image
import openai
import json
import random
from typing import List
from datetime import datetime, timezone
from io import BytesIO

user_agents = [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0'
]

def get_headers():
    return {
        'User-Agent': random.choice(user_agents),
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.5',
        'Accept-Encoding': 'gzip, deflate, br',
        'DNT': '1',
        'Connection': 'keep-alive',
        'Upgrade-Insecure-Requests': '1',
    }

class XHSContentResponse(BaseModel):
    url: str
    success: bool
    link_domain: str
    title: str
    text_content: str
    image_urls: list[str]
    image_base64_pngs: list[str]
    main_content: str

def summarize_image(image_url: str) -> str:
    try:
        response = requests.get(image_url)
        response.raise_for_status()
        image = Image.open(io.BytesIO(response.content))
        
        # Convert image to base64
        buffered = io.BytesIO()
        image.save(buffered, format="PNG")
        img_str = base64.b64encode(buffered.getvalue()).decode()
        
        response = openai.ChatCompletion.create(
            model="gpt-4o",
            messages=[
                {
                    "role": "user",
                    "content": [
                        {"type": "text", "text": "Describe this image concisely in one sentence."},
                        {"type": "image_url", "image_url": f"data:image/png;base64,{img_str}"}
                    ],
                }
            ],
        )
        
        return response.choices[0].message['content'].strip()
    except Exception as e:
        return f"Failed to summarize image: {str(e)}"

def extract_png_from_urls(image_urls: List[str]) -> List[str]:
    base64_pngs = []
    for url in image_urls:
        try:
            response = requests.get(url)
            response.raise_for_status()
            img = Image.open(BytesIO(response.content))
            img = img.convert('RGB')
            buffered = BytesIO()
            img.save(buffered, format="PNG")
            img_str = base64.b64encode(buffered.getvalue()).decode()
            base64_pngs.append(img_str)
        except Exception as e:
            print(f"Failed to extract PNG from {url}: {str(e)}")
    return base64_pngs

def extract_xhs_content(url: str) -> XHSContentResponse:
    try:
        response = requests.get(url, headers=get_headers())
        response.raise_for_status()
        html_content = response.content.decode('utf-8')
        soup = BeautifulSoup(html_content, 'html.parser')
    
        # Look for a script tag that might contain the JSON data
        script_tag = soup.find('script', string=lambda t: t and '__INITIAL_STATE__' in t)
        
        if script_tag:
            # Extract the JSON data from the HTML
            match = re.search(r'window\.__INITIAL_STATE__=(.*?)</script>', html_content, re.DOTALL)
            if not match:
                raise ValueError("Could not find JSON data in the HTML content")
            
            json_text = match.group(1).strip()
            json_text = re.sub(r'undefined', 'null', json_text)
            json_text = re.sub(r',\s*}', '}', json_text)
            json_text = re.sub(r',\s*]', ']', json_text)
            
            # Parse the JSON data
            try:
                data = json.loads(json_text)
            except json.JSONDecodeError as e:
                print(f"JSON Decode Error: {str(e)}")
                print(f"Problematic JSON data: {json_text[:100]}...") # Print the first 100 characters
                raise

            # Find the first (and likely only) key in the noteDetailMap
            note_id = next(iter(data['note']['noteDetailMap']))
            note_data = data['note']['noteDetailMap'][note_id]['note']
            
            # Extract the required data
            structured_data = {
                "title": note_data.get('title', ''),
                "author": note_data['user']['nickname'],
                "uid": note_data['user']['userId'],
                "note_id": note_id,
                "description": note_data.get('desc', ''),
                "tags": [tag['name'] for tag in note_data.get('tagList', [])],
                "image_urls": [img['urlDefault'] for img in note_data.get('imageList', [])],
                "time": timestamp_to_utc(note_data.get('time')),
                "last_update_time": timestamp_to_utc(note_data.get('lastUpdateTime')),
                "ip_location": note_data.get('ipLocation', ''),
                "type": note_data.get('type', ''),
                "like_count": note_data['interactInfo'].get('likedCount', '0'),
                "comment_count": note_data['interactInfo'].get('commentCount', '0'),
                "collect_count": note_data['interactInfo'].get('collectedCount', '0'),
                "share_count": note_data['interactInfo'].get('shareCount', '0'),
            }

            image_base64_pngs = extract_png_from_urls(structured_data['image_urls'])

            return XHSContentResponse(
                url=url,
                success=True,
                link_domain=urlparse(url).netloc,
                title=structured_data['title'],
                text_content=structured_data['description'],
                image_urls=structured_data['image_urls'],
                image_base64_pngs=image_base64_pngs,
                main_content=json.dumps(structured_data, ensure_ascii=False)
            )
    except Exception as e:
        print(f"Error in extract_xhs_content: {str(e)}")
        return XHSContentResponse(
            url=url,
            success=False,
            link_domain=urlparse(url).netloc,
            title="",
            text_content="",
            image_urls=[],
            image_base64_pngs=[],
            main_content=f"Failed to extract Xiaohongshu content: {str(e)}"
        )

def timestamp_to_utc(timestamp):
    if timestamp:
        return datetime.fromtimestamp(timestamp / 1000, tz=timezone.utc).isoformat()
    return None

if __name__ == "__main__":
    url = "http://xhslink.com/a/eio5fTGOHFNX"
    response = extract_xhs_content(url)
    print(response)
