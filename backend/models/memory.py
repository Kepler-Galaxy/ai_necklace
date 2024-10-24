from datetime import datetime
from enum import Enum
from typing import List, Optional, Dict

from pydantic import BaseModel, Field, validator

from models.chat import Message
from models.transcript_segment import TranscriptSegment
from utils.memories.web_content import WebContentResponseV2
from loguru import logger


class CategoryEnum(str, Enum):
    personal = 'personal'
    education = 'education'
    health = 'health'
    finance = 'finance'
    legal = 'legal'
    philosophy = 'philosophy'
    spiritual = 'spiritual'
    science = 'science'
    entrepreneurship = 'entrepreneurship'
    parenting = 'parenting'
    romance = 'romantic'
    travel = 'travel'
    inspiration = 'inspiration'
    technology = 'technology'
    business = 'business'
    social = 'social'
    work = 'work'
    sports = 'sports'
    politics = 'politics'
    literature = 'literature'
    history = 'history'
    architecture = 'architecture'
    other = 'other'


class UpdateMemory(BaseModel):
    title: Optional[str] = None
    overview: Optional[str] = None


class MemoryPhoto(BaseModel):
    base64: str
    description: str


class PluginResult(BaseModel):
    plugin_id: Optional[str]
    content: str


class ActionItem(BaseModel):
    description: str = Field(description="The action item to be completed")
    completed: bool = False  # IGNORE ME from the model parser


class Event(BaseModel):
    title: str = Field(description="The title of the event")
    description: str = Field(description="A brief description of the event", default='')
    start: datetime = Field(description="The start date and time of the event")
    duration: int = Field(description="The duration of the event in minutes", default=30)
    created: bool = False


# TODO(yiqi): Structured is a struct for all kinds of memories. Not limited to conversations.
# refactor it by moving conservation related fields to a new struct.
class Structured(BaseModel):
    title: str = Field(description="A title/name for this conversation", default='')
    overview: str = Field(
        description="A brief overview of the conversation, highlighting the key details from it",
        default='',
    )
    emoji: str = Field(description="An emoji to represent the memory", default='🧠')
    category: CategoryEnum = Field(description="A category for this memory", default=CategoryEnum.other)
    key_points: List[str] = Field(description="A list of key points", default=[])
    action_items: List[ActionItem] = Field(description="A list of action items from the conversation", default=[])
    events: List[Event] = Field(
        description="A list of events extracted from the conversation, that the user must have on his calendar.",
        default=[],
    )

    def __str__(self):
        result = (f"{str(self.title).capitalize()} ({str(self.category.value).capitalize()})\n"
                  f"{str(self.overview).capitalize()}\n"
                  f"Key Points:\n"
                  f"{str(self.key_points).capitalize()}\n")

        if self.action_items:
            result += "Action Items:\n"
            for item in self.action_items:
                result += f"- {item.description}\n"

        if self.events:
            result += "Events:\n"
            for event in self.events:
                result += f"- {event.title} ({event.start} - {event.duration} minutes)\n"
        return result.strip()


class Geolocation(BaseModel):
    google_place_id: Optional[str] = None
    latitude: float
    longitude: float
    address: Optional[str] = None
    location_type: Optional[str] = None


class MemorySource(str, Enum):
    friend = 'friend'
    openglass = 'openglass'
    screenpipe = 'screenpipe'
    workflow = 'workflow'
    wechat_article = 'wechat_article' # TODO: keep for validation correctness, remove this once migration is done
    web_link = 'web_link'

class ExternalLinkDescription(BaseModel):
    link: str
    metadata: Dict

    @staticmethod
    # currently only support article extraction from web links
    def from_web_article(article_link: str):
        return ExternalLinkDescription(link=article_link, metadata={"source": "web_article"})
    
class ImageDescription(BaseModel):
    is_ocr: bool = Field(description="Whether the image primarily contains text (OCR)")
    ocr_content: str = Field(description="Text extracted from OCR")
    description: str = Field(description="Description of the image")

class ExternalLink(BaseModel):
    external_link_description: ExternalLinkDescription
    web_content_response: Optional[WebContentResponseV2] = None
    web_photo_understanding: Optional[List[ImageDescription]] = None

    @validator('web_content_response', pre=True)
    def validate_web_content_response(cls, v):
        if isinstance(v, dict):
            if 'version' in v and v['version'] == 2:
                return WebContentResponseV2(**v)
            else:
                return WebContentResponseV2.from_v1(v)
        return v

class MemoryVisibility(str, Enum):
    private = 'private'
    shared = 'shared'
    public = 'public'


class PostProcessingStatus(str, Enum):
    not_started = 'not_started'
    in_progress = 'in_progress'
    completed = 'completed'
    canceled = 'canceled'
    failed = 'failed'

class MemoryStatus(str, Enum):
    in_progress = 'in_progress'
    processing = 'processing'
    completed = 'completed'
    failed = 'failed'


class PostProcessingModel(str, Enum):
    fal_whisperx = 'fal_whisperx'


class MemoryPostProcessing(BaseModel):
    status: PostProcessingStatus
    model: PostProcessingModel
    fail_reason: Optional[str] = None


class MemoryConnection(BaseModel):
    memory_id: str
    explanation: str


class Memory(BaseModel):
    id: str
    uid: str
    created_at: datetime
    started_at: Optional[datetime]
    finished_at: Optional[datetime]

    source: Optional[MemorySource] = MemorySource.friend  # TODO: once released migrate db to include this field
    language: Optional[str] = None  # applies only to Friend # TODO: once released migrate db to default 'en'

    structured: Structured
    transcript_segments: Optional[List[TranscriptSegment]] = []
    geolocation: Optional[Geolocation] = None
    photos: List[MemoryPhoto] = []

    plugins_results: List[PluginResult] = []

    external_data: Optional[Dict] = None
    external_link: Optional[ExternalLink] = None

    postprocessing: Optional[MemoryPostProcessing] = None

    discarded: bool = False
    deleted: bool = False
    visibility: MemoryVisibility = MemoryVisibility.private

    processing_memory_id: Optional[str] = None

    connections: List[MemoryConnection] = []

    @staticmethod
    def memories_to_string(memories: List['Memory'], include_action_items=True, include_raw_data=False, include_connections=False) -> str:
        result = []
        for i, memory in enumerate(memories):
            if isinstance(memory, dict):
                memory = Memory(**memory)
            formatted_date = memory.created_at.strftime("%d %b, at %H:%M")
            memory_str = (f"Memory #{i + 1}\n"
                          f"{formatted_date} ({str(memory.structured.category.value).capitalize()})\n"
                          f"{str(memory.structured.title).capitalize()}\n"
                          f"{str(memory.structured.overview).capitalize()}\n"
                          f"{str(memory.structured.key_points).capitalize()}\n")

            if include_action_items and memory.structured.action_items:
                memory_str += "Action Items:\n"
                for item in memory.structured.action_items:
                    memory_str += f"- {item.description}\n"

            if include_raw_data:
                if memory.transcript_segments:
                    memory_str += "Transcript Segments:\n"
                    memory_str += memory.get_transcript(include_timestamps=True) + "\n"
                elif memory.external_link and memory.external_link.web_content_response:
                    memory_str += "Web Article and related image descriptions:\n"
                    memory_str += f"{memory.get_web_content()}\n"

            if include_connections and memory.connections:
                memory_str += "Connections:\n"
                for connection in memory.connections:
                    memory_str += f"- {connection.memory_id}: {connection.explanation}\n"

            result.append(memory_str.strip())

        return "\n\n---------------------\n\n".join(result).strip()

    def get_transcript(self, include_timestamps: bool) -> str:
        # Warn: missing transcript for workflow source
        return TranscriptSegment.segments_as_string(self.transcript_segments, include_timestamps=include_timestamps)
    
    def get_web_content(self) -> Optional[str]:
        if self.external_link and self.external_link.web_content_response:
            content = f"Title: {self.external_link.web_content_response.response.title}\n"
            content += f"Content: {self.external_link.web_content_response.response.main_content}\n"
            
            if self.external_link.web_photo_understanding:
                for i, image_desc in enumerate(self.external_link.web_photo_understanding, 1):
                    content += f"\nImage {i}:\n"
                    if image_desc.is_ocr:
                        content += f"OCR Content: {image_desc.ocr_content}\n"
                    content += f"Description: {image_desc.description}\n"
            
            return content.strip()
        return None
    
    def as_dict_cleaned_dates(self):
        self.structured.events = [event.as_dict_cleaned_dates() for event in self.structured.events]
        memory_dict = self.dict()
        memory_dict['created_at'] = memory_dict['created_at'].isoformat()
        memory_dict['started_at'] = memory_dict['started_at'].isoformat() if memory_dict['started_at'] else None
        memory_dict['finished_at'] = memory_dict['finished_at'].isoformat() if memory_dict['finished_at'] else None
        return memory_dict
    
class CreateMemory(BaseModel):
    started_at: datetime
    finished_at: datetime
    transcript_segments: Optional[List[TranscriptSegment]] = None
    geolocation: Optional[Geolocation] = None

    photos: List[MemoryPhoto] = []
    external_link: ExternalLink = None

    source: MemorySource = MemorySource.friend
    language: Optional[str] = None

    processing_memory_id: Optional[str] = None

    def get_transcript(self, include_timestamps: bool) -> str:
        return TranscriptSegment.segments_as_string(self.transcript_segments, include_timestamps=include_timestamps)

class MemoryConnectionsGraphRequest(BaseModel):
    memory_ids: List[str]
    memory_connection_depth: int = Field(ge=1, le=5)  # Limit depth to prevent excessive recursion

class MemoryConnectionNode(BaseModel):
    memory_id: str
    children: List['MemoryConnectionNode'] = []
    explanation: Optional[str] = None
    memory: Optional[Dict] = None

class MemoryConnectionsGraphResponse(BaseModel):
    forest: List[MemoryConnectionNode]

class WorkflowMemorySource(str, Enum):
    audio = 'audio_transcript'
    other = 'other_text'


class WorkflowCreateMemory(BaseModel):
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    text: str
    text_source: WorkflowMemorySource = WorkflowMemorySource.audio
    geolocation: Optional[Geolocation] = None

    source: MemorySource = MemorySource.workflow
    language: Optional[str] = None

    def get_transcript(self, include_timestamps: bool) -> str:
        return self.text


class CreateMemoryResponse(BaseModel):
    memory: Memory
    messages: List[Message] = []


class SetMemoryEventsStateRequest(BaseModel):
    events_idx: List[int]
    values: List[bool]
