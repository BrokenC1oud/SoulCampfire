from typing import List, Union, Optional, Any, Literal, Callable

from aiohttp import web
import asyncio
from pydantic import BaseModel, ConfigDict, TypeAdapter


class TextElement(BaseModel):
    type: Literal["text"]
    data: dict[str, str]

    def text(self) -> str:
        return self.data.get("text")

    def __str__(self):
        return self.text()


class ReplyElement(BaseModel):
    type: Literal["reply"]
    data: dict[str, str]

    def reply_to(self) -> int:
        return int(self.data.get("id"))

    def __str__(self):
        return f"[-> {self.reply_to()}]"


class FaceElement(BaseModel):
    type: Literal["face"]
    data: dict[str, Any]


class ImageElement(BaseModel):
    type: Literal["image"]
    data: dict[str, Any]


class AtElement(BaseModel):
    type: Literal["at"]
    data: dict[str, Any]


class FileElement(BaseModel):
    type: Literal["file"]
    data: dict[str, Any]


MessageElement = Union[TextElement, ReplyElement, FaceElement, ImageElement, AtElement, FileElement]


# --- Metadata Models ---

class Sender(BaseModel):
    user_id: int
    nickname: Optional[str] = None
    card: Optional[str] = ""
    role: Optional[str] = None


class RawData(BaseModel):
    """Captures the nested 'raw' object for deep inspection if needed"""
    msgId: str
    msgTime: str
    elements: List[dict] = []
    # Add other fields from the 'raw' key as needed


class FileInfo(BaseModel):
    id: str
    name: str
    size: int
    busid: int


# --- Main Event Model ---

class BaseEvent(BaseModel):
    """Common fields for every OneBot event"""
    model_config = ConfigDict(extra="ignore")
    time: int
    self_id: int
    post_type: str


class GroupMessageEvent(BaseEvent):
    """post_type == 'message'"""
    post_type: Literal["message"]
    message_type: str
    sub_type: str
    message_id: int
    user_id: int
    message: List[MessageElement]
    raw_message: str
    sender: Sender
    group_id: int


class GroupUploadNoticeEvent(BaseEvent):
    """post_type == 'notice' and notice_type == 'group_upload'"""
    post_type: Literal["notice"]
    notice_type: Literal["group_upload"]
    group_id: int
    user_id: int
    file: FileInfo


OneBotEvent = Union[GroupMessageEvent, GroupUploadNoticeEvent]
OneBotEventAdapter = TypeAdapter(OneBotEvent)


class HttpServer:
    def __init__(self, port: int, message_queue: asyncio.Queue, token: str = ''):
        self.port = port
        self.token = token
        self.app = web.Application()
        self.app.add_routes([
            web.post("/", self._handler)
        ])
        self.message_queue = message_queue

    async def _handler(self, request: web.Request) -> web.Response:
        try:
            data = await request.json()
            event = OneBotEventAdapter.validate_python(data)
            print(event)
            await self.message_queue.put(event)
        except Exception as e:
            print(data)
            raise e
        return web.json_response({})
