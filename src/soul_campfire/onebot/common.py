import asyncio
from pydantic import BaseModel


class Anonymous(BaseModel):
    id: int
    name: str
    flag: str


class Sender(BaseModel):
    user_id: int
    nickname: str


class MessageSegment(BaseModel):
    type: str
    data: dict


Message = list[MessageSegment]