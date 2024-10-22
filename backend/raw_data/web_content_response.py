from pydantic import BaseModel, Field
from typing import Union, Dict, Any, List, Literal
from datetime import datetime
from urllib.parse import urlparse

class BaseWebContentResponse(BaseModel):
    success: bool
    url: str
    title: str
    content_type: Literal["wechat", "little_red_book", "general"]

class WeChatContentResponse(BaseWebContentResponse):
    content_type: Literal["wechat"] = "wechat"
    #TODO(yiqi): add more related tags so that user memory can be grouped better
    # author: str
    # publish_time: str
    # account_name: str
    main_content: str

class LittleRedBookContentResponse(BaseWebContentResponse):
    content_type: Literal["little_red_book"] = "little_red_book"
    author: str
    uid: str
    note_id: str
    time: datetime
    last_update_time: datetime
    ip_location: str

    #TODO: scrape these fields or not?
    # likes: int
    # comments: int
    # collect_count: int
    # share_count: int

    description: str
    tags: List[str]
    text_content: str
    image_urls: List[str]
    # don't store these fields now, since our mongodb is limited.
    image_base64_jpegs: List[str] = Field(..., exclude=True)
    low_res_image_base64_jpegs: List[str] = Field(..., exclude=True)

    @property
    def main_content(self):
        return self.text_content

class GeneralWebContentResponse(BaseWebContentResponse):
    content_type: Literal["general"] = "general"
    main_content: str

# TODO(yiqi): v1 model with existing data in MongoDB, need to migrate to v2 sometime.
class WebContentResponse(BaseModel):
    success: bool
    title: str
    main_content: str
    url: str

class WebContentResponseV2(BaseModel):
    response: Union[WeChatContentResponse, LittleRedBookContentResponse, GeneralWebContentResponse] = Field(..., discriminator='content_type')
    raw_data: Dict[str, Any]
    version: Literal[1, 2] = 2

    class Config:
        use_enum_values = True

    @classmethod
    def from_v1(cls, v1_response: Dict[str, Any]):
        #print(v1_response)
        
        url = v1_response.get('url', '')
        success = v1_response.get('success', False)
        title = v1_response.get('title', '')
        main_content = v1_response.get('main_content', '')

        parsed_url = urlparse(url)
        
        if parsed_url.netloc == "mp.weixin.qq.com":
            response = WeChatContentResponse(
                success=success,
                url=url,
                title=title,
                content_type="wechat",
                main_content=main_content
            )
        else:
            response = GeneralWebContentResponse(
                success=success,
                url=url,
                title=title,
                content_type="general",
                main_content=main_content
            )

        return cls(
            response=response,
            raw_data={},
            version=1
        )
