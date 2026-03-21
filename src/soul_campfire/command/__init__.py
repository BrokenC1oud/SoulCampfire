import inspect
from inspect import Signature
from typing import Callable, Any

from sqlalchemy.orm import Session

from soul_campfire.onebot import OneBotEvent
from soul_campfire.model import User

class CommandData:
    func: Callable[[Any], str]
    sig: Signature

    def __init__(self, func: Callable[[Any], str], sig: Signature):
        self.func = func
        self.sig = sig


class CommandParser:
    def __init__(self, db_session: Session):
        self.commands: dict[str, CommandData] = {}
        self.db_session = db_session

    def register(self, name: str = None):
        def decorator(func: Callable[[Any], str]):
            cmd_name = name or func.__name__
            self.commands[cmd_name] = CommandData(
                func=func,
                sig=inspect.signature(func),
            )
            return func
        return decorator

    def execute(self, input_string: str, message_event: OneBotEvent):
        parts = input_string.split()
        if not parts: return None

        cmd_name, *raw_args = parts
        if cmd_name not in self.commands:
            print("Unhandled message")
            return None

        cmd_info = self.commands[cmd_name]
        params = list(cmd_info.sig.parameters.values())

        injected_params = self.preprocess(message_event)
        injected_params["event"] = message_event

        validated_args = []
        try:
            for arg, param in zip(raw_args, params):
                t = param.annotation
                validated_args.append(t(arg) if t is not inspect.Parameter.empty else arg)
        except ValueError as e:
            raise e

        return cmd_info.func(*validated_args, **injected_params)

    def preprocess(self, message: OneBotEvent) -> dict[str, object]:
        result = {}
        user = self.db_session.query(User).filter(User.id == message.user_id).first()

        if user:
            result["user"] = user

        return result
