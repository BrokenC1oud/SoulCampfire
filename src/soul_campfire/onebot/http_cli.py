from typing import Literal, Optional, overload

import requests
from pydantic import BaseModel

from .common import Anonymous, Message, Sender


class Response(BaseModel):
    data: dict | list
    echo: Optional[str]
    message: str
    retcode: int
    status: Literal["ok"]
    wording: str


class SendPrivateMsgResp(BaseModel):
    message_id: int


class SendGroupMsgResp(BaseModel):
    message_id: int


class GetMsgResp(BaseModel):
    time: int
    message_type: Literal["group", "private"]
    message_id: int
    real_id: int
    sender: Sender
    message: Message


class GetForwardMsgResp(BaseModel):
    message: Message


class GetLoginInfoResp(BaseModel):
    user_id: int
    nickname: str


class GetStrangerInfoResp(BaseModel):
    user_id: int
    nickname: str
    sex: Literal["male", "female", "unknown"]
    age: int


class GetFriendListResp(BaseModel):
    user_id: int
    nickname: str
    remark: str


class GetGroupInfoResp(BaseModel):
    group_id: int
    group_name: str
    member_count: int
    max_member_count: int


class GetGroupListResp(BaseModel):
    group_id: int
    group_name: str
    member_count: int
    max_member_count: int


class GetGroupMemberInfoResp(BaseModel):
    group_id: int
    user_id: int
    nickname: str
    card: str
    sex: Literal["male", "female", "unknown"]
    age: int
    area: str
    join_time: int
    last_sent_time: int
    level: str
    role: Literal["owner", "admin", "member"]
    unfriendly: bool
    title: str
    title_expire_time: int
    card_changeable: bool


class GetGroupMemberListResp(BaseModel):
    group_id: int
    user_id: int
    nickname: str
    card: str
    join_time: int
    last_sent_time: int
    level: str
    role: Literal["owner", "admin", "member"]
    unfriendly: bool
    card_changeable: bool


class Talkative(BaseModel):
    user_id: int
    nickname: str
    avatar: str
    day_count: int


class Honor(BaseModel):
    user_id: int
    nickname: str
    avatar: str
    description: str


class GetGroupHonorInfoResp(BaseModel):
    group_id: int
    current_talkative: Optional[Talkative] = None
    talkative_list: Optional[list[Honor]] = None
    performer_list: Optional[list[Honor]] = None
    legend_list: Optional[list[Honor]] = None
    strong_newbie_list: Optional[list[Honor]] = None
    emotion_list: Optional[list[Honor]] = None


class GetCookiesResp(BaseModel):
    cookies: str


class GetCSRFTokenResp(BaseModel):
    token: int


class GetCredentialsResp(BaseModel):
    cookies: str
    csrf_token: int


class GetRecordResp(BaseModel):
    file: str


class GetImageResp(BaseModel):
    file: str


class CanSendImageResp(BaseModel):
    yes: bool


class CanSendRecordResp(BaseModel):
    yes: bool


class GetStatusResp(BaseModel):
    online: bool
    good: bool


class GetVersionInfoResp(BaseModel):
    app_name: str
    app_version: str
    protocol_version: str


class HttpClient:
    def __init__(self, host: str, token: str = None):
        self.host = host
        self.token = token

    def _api_call(self, endpoint: str, **kwargs) -> dict:
        res = requests.get(
            f"{self.host}/{endpoint}",
            params=kwargs,
            headers={"Authorization": f"Bearer {self.token}"},
        )
        res.raise_for_status()
        res_v = Response.model_validate_json(res.content)
        return res_v.data

    def send_private_msg(
            self, user_id: int, message: str, auto_escape: Optional[bool] = False
    ) -> SendPrivateMsgResp:
        return SendPrivateMsgResp(
            **self._api_call(
                "send_private_msg",
                user_id=user_id,
                message=message,
                auto_escape=auto_escape,
            )
        )

    def send_group_msg(
            self, group_id: int, message: str, auto_escape: Optional[bool] = False
    ) -> SendGroupMsgResp:
        return SendGroupMsgResp(
            **self._api_call(
                "send_group_msg",
                group_id=group_id,
                message=message,
                auto_escape=auto_escape,
            )
        )

    @overload
    def send_msg(
            self,
            message: str,
            user_id: int,
            message_type: Optional[Literal["private"]] = None,
            auto_escape: Optional[bool] = False,
    ) -> SendPrivateMsgResp:
        ...

    @overload
    def send_msg(
            self,
            message: str,
            group_id: int,
            message_type: Optional[Literal["group"]] = None,
            auto_escape: Optional[bool] = False,
    ) -> SendGroupMsgResp:
        ...

    def send_msg(
            self,
            message: str,
            message_type: Optional[Literal["private", "group"]] = None,
            user_id: Optional[int] = None,
            group_id: Optional[int] = None,
            auto_escape: Optional[bool] = False,
    ) -> SendPrivateMsgResp | SendGroupMsgResp:
        if group_id:
            return self.send_group_msg(group_id, message, auto_escape)
        elif user_id:
            return self.send_private_msg(user_id, message, auto_escape)
        else:
            raise ValueError("Invalid Argument")

    def delete_msg(self, message_id: int) -> None:
        self._api_call("delete_msg", message_id=message_id)

    def get_msg(self, message_id: int) -> GetMsgResp:
        return GetMsgResp(**self._api_call("get_msg", message_id=message_id))

    def get_forward_msg(self, id_: str) -> GetForwardMsgResp:
        return GetForwardMsgResp(**self._api_call("get_forward_msg", id=id_))

    def send_like(self, user_id: int, times: Optional[int] = 1) -> None:
        self._api_call("send_like", user_id=user_id, times=times)

    def set_group_kick(
            self, group_id: int, user_id: int, reject_add_request: Optional[bool] = False
    ) -> None:
        self._api_call(
            "set_group_kick",
            group_id=group_id,
            user_id=user_id,
            reject_add_request=reject_add_request,
        )

    def set_group_ban(
            self, group_id: int, user_id: int, duration: Optional[int] = 30 * 60
    ) -> None:
        self._api_call(
            "set_group_ban", group_id=group_id, user_id=user_id, duration=duration
        )

    def set_group_anonymous_ban(
            self,
            group_id: int,
            anonymous: Optional[Anonymous] = None,
            anonymous_flag: Optional[str] = None,
            flag: Optional[str] = None,
            duration: Optional[int] = 30 * 60,
    ) -> None:
        self._api_call(
            "set_group_anonymous_ban",
            group_id=group_id,
            anonymous=anonymous,
            anonymous_flag=anonymous_flag,
            flag=flag,
            duration=duration,
        )

    def set_group_whole_ban(self, group_id: int, enable: Optional[bool] = True) -> None:
        self._api_call("set_group_whole_ban", group_id=group_id, enable=enable)

    def set_group_admin(
            self, group_id: int, user_id: int, enable: Optional[bool] = True
    ) -> None:
        self._api_call(
            "set_group_admin", group_id=group_id, user_id=user_id, enable=enable
        )

    def set_group_anonymous(self, group_id: int, enable: Optional[bool] = True) -> None:
        self._api_call("set_group_anonymous", group_id=group_id, enable=enable)

    def set_group_card(
            self, group_id: int, user_id: int, card: Optional[str] = ""
    ) -> None:
        self._api_call("set_group_card", group_id=group_id, user_id=user_id, card=card)

    def set_group_name(self, group_id: int, group_name: str) -> None:
        self._api_call("set_group_name", group_id=group_id, group_name=group_name)

    def set_group_leave(self, group_id: int, is_dismiss: Optional[bool] = False):
        self._api_call("set_group_leave", group_id=group_id, is_dismiss=is_dismiss)

    def set_group_special_title(
            self,
            group_id: int,
            user_id: int,
            special_title: Optional[str] = "",
            duration: Optional[int] = -1,
    ) -> None:
        self._api_call(
            "set_group_special_title",
            group_id=group_id,
            user_id=user_id,
            special_title=special_title,
            duration=duration,
        )

    def set_friend_add_request(
            self, flag: str, approve: Optional[bool] = True, remark: Optional[str] = ""
    ) -> None:
        self._api_call(
            "set_friend_add_request", flag=flag, approve=approve, remark=remark
        )

    @overload
    def set_group_add_request(
            self,
            flag: str,
            sub_type: str,
            approve: Optional[bool] = True,
            reason: Optional[str] = "",
    ) -> None:
        ...

    @overload
    def set_group_add_request(
            self,
            flag: str,
            type_: str,
            approve: Optional[bool] = True,
            reason: Optional[str] = "",
    ) -> None:
        ...

    def set_group_add_request(
            self,
            flag: str,
            sub_type: Optional[str] = "",
            type_: Optional[str] = "",
            approve: Optional[bool] = True,
            reason: Optional[str] = "",
    ) -> None:
        self._api_call(
            "set_group_add_request",
            flag=flag,
            sub_type=sub_type or type_,
            approve=approve,
            reason=reason,
        )

    def get_login_info(self) -> GetLoginInfoResp:
        return GetLoginInfoResp(**self._api_call("get_login_info"))

    def get_stranger_info(
            self, user_id: int, no_cache: Optional[bool] = False
    ) -> GetStrangerInfoResp:
        return GetStrangerInfoResp(
            **self._api_call("get_stranger_info", user_id=user_id, no_cache=no_cache)
        )

    def get_friend_list(self) -> list[GetFriendListResp]:
        return [GetFriendListResp(**_) for _ in self._api_call("get_friend_list")]

    def get_group_info(
            self, group_id: int, no_cache: Optional[bool] = False
    ) -> GetGroupInfoResp:
        return GetGroupInfoResp(
            **self._api_call("get_group_info", group_id=group_id, no_cache=no_cache)
        )

    def get_group_list(self) -> list[GetGroupListResp]:
        return [GetGroupListResp(**_) for _ in self._api_call("get_group_list")]

    def get_group_member_info(
            self, group_id: int, user_id: int, no_cache: Optional[bool] = False
    ) -> GetGroupMemberInfoResp:
        return GetGroupMemberInfoResp(
            **self._api_call(
                "get_group_member_info",
                group_id=group_id,
                user_id=user_id,
                no_cache=no_cache,
            )
        )

    def get_group_member_list(self, group_id: int) -> list[GetGroupMemberListResp]:
        return [
            GetGroupMemberListResp(**_)
            for _ in self._api_call("get_group_member_list", group_id=group_id)
        ]

    def get_group_honor_info(
            self,
            group_id: int,
            type_: Literal[
                "talkative", "performer", "legend", "strong_newbie", "emotion", "all"
            ],
    ) -> GetGroupHonorInfoResp:
        return GetGroupHonorInfoResp(
            **self._api_call("get_group_honor_info", group_id=group_id, type=type_)
        )

    def get_cookies(self, domain: Optional[str] = "") -> GetCookiesResp:
        return GetCookiesResp(**self._api_call("get_cookies", domain=domain))

    def get_csrf_token(self) -> GetCSRFTokenResp:
        return GetCSRFTokenResp(**self._api_call("get_csrf_token"))

    def get_credentials(self, domain: Optional[str] = "") -> GetCredentialsResp:
        return GetCredentialsResp(**self._api_call("get_credentials", domain=domain))

    def get_record(self, file: str, out_format: str) -> GetRecordResp:
        return GetRecordResp(
            **self._api_call("get_record", file=file, out_format=out_format)
        )

    def get_image(self, file: str) -> GetImageResp:
        return GetImageResp(**self._api_call("get_image", file=file))

    def can_send_image(self) -> CanSendImageResp:
        return CanSendImageResp(**self._api_call("can_send_image"))

    def can_send_record(self) -> CanSendRecordResp:
        return CanSendRecordResp(**self._api_call("can_send_record"))

    def get_status(self) -> GetStatusResp:
        return GetStatusResp(**self._api_call("get_status"))

    def get_version_info(self) -> GetVersionInfoResp:
        return GetVersionInfoResp(**self._api_call("get_version_info"))

    def set_restart(self, delay: Optional[int] = 0) -> None:
        self._api_call("set_restart", delay=delay)

    def clean_cache(self) -> None:
        self._api_call("clean_cache")
