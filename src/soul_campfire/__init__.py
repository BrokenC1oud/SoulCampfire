import asyncio
import datetime
import os
import random
from typing import Optional

import dotenv
from sqlalchemy import desc

from soul_campfire.adapter import Adapter
from soul_campfire.command import CommandParser
from soul_campfire.model import User, Session, Trait, School, Practice
from soul_campfire.onebot import OneBotEvent

db_session = Session()
command_parser = CommandParser(db_session)


@command_parser.register("检测灵根")
def discover_soul(user: User = None, event: OneBotEvent = None):
    if user is None:
        trait = random.choice(list(Trait))
        user = User(
            id=event.user_id,
            cultivation=0,
            trait=trait,
            school=School.rogue,
        )
        db_session.add(user)
        db_session.commit()
        return f"欢迎踏入仙途，你的灵根是：{trait.value}, 你将从炼气一层开始"
    else:
        return "你已经进入修仙世界了！"


@command_parser.register("我的灵根")
def my_soul(user: User = None, event: OneBotEvent = None):
    return f"""{event.sender.nickname} 的天命玉牒:
    宗门: {user.school.value}
    灵根: {user.trait.value}
    修为: {user.cultivation:.2f}"""


def create_practice(user: User, cultivation: int, cooldown: int) -> Optional[Practice]:
    practise: Practice = db_session.query(Practice).filter(Practice.user == user.id).order_by(
        desc(Practice.time)).first()
    if practise is None:
        in_cooldown = False
    else:
        dt = datetime.datetime.now() - practise.time
        in_cooldown = dt < datetime.timedelta(minutes=practise.cooldown)
    if in_cooldown:
        return None
    else:
        return Practice(
            user=user.id,
            cultivation=cultivation,
            cooldown=cooldown,
            time=datetime.datetime.now(),
        )


@command_parser.register("闭关修炼")
def practice(user: User = None, event: OneBotEvent = None):
    success = True if random.random() < 0.8 else False
    practise = create_practice(user, cultivation=random.randint(5, 20) if success else random.randint(-10, -5),
                               cooldown=random.randint(10, 15))
    if practise is None:
        return "修炼还在冷却中！"
    else:
        db_session.add(practise)
        user.cultivation += practise.cultivation
        db_session.commit()
        if practise.cultivation > 0:
            return ("闭关成功\n"
                    f"你的修为增长了{practise.cultivation}点\n"
                    f"还需要{practise.cooldown}分钟才能继续修炼")
        else:
            return ("闭关失败\n"
                    f"你心浮气躁 无法凝神 白白浪费了灵气 你的修为减少了{-practise.cultivation}\n"
                    f"还需要{practise.cooldown}分钟才能继续修炼")


@command_parser.register("深度闭关")
def deep_practice(user: User = None, event: OneBotEvent = None):
    practise = create_practice(user, cultivation=random.randint(50, 200), cooldown=random.randint(60, 480))
    if practise is None:
        return "修炼还在冷却中！"
    else:
        db_session.add(practise)
        user.cultivation += practise.cultivation
        db_session.commit()
        return ("开始深度闭关\n"
                f"此次闭关将消耗{practise.cooldown}分钟")


@command_parser.register("查看闭关")
def query_practice(user: User = None, event: OneBotEvent = None):
    practise: Practice = db_session.query(Practice).filter(Practice.user == user.id).order_by(
        desc(Practice.time)).first()
    if practise is None:
        return "当前不在闭关"
    else:
        if practise.time + datetime.timedelta(minutes=practise.cooldown) < datetime.datetime.now():
            return "当前不在闭关"
        else:
            return ("当前正在闭关\n"
                    f"还需要{((practise.time + datetime.timedelta(minutes=practise.cooldown)) - datetime.datetime.now()).seconds / 60}分钟结束")


@command_parser.register("强行出关")
def out_of_practice(user: User = None, event: OneBotEvent = None):
    practise: Practice = db_session.query(Practice).filter(Practice.user == user.id).order_by(
        desc(Practice.time)).first()
    if practise is None:
        return "您当前不在闭关"
    else:
        if practise.time + datetime.timedelta(minutes=practise.cooldown) < datetime.datetime.now():
            return "您当前不在闭关"
        else:
            time_elapsed = (datetime.datetime.now() - practise.time).total_seconds()
            ratio = max(0, min(1, time_elapsed / practise.cooldown))
            cultivation_delta = practise.cultivation * (1 - ratio)
            user.cultivation -= cultivation_delta
            practise.cooldown = 0
            db_session.commit()
            return ("您已强行出关\n"
                    f"损失修为:{cultivation_delta:.2f}")


@command_parser.register("拜入宗门")
def join_school(school: str = None, user: User = None, event: OneBotEvent = None):
    if school is None:
        return "请选择你的宗门：/拜入宗门 <宗门>"
    else:
        user.school = School.from_chinese(school)
        db_session.commit()
        return (f"你已加入 {user.school.value}")


def main():
    dotenv.load_dotenv()

    adap = Adapter(
        server_port=int(os.getenv("SERVER_PORT")),
        server_token=os.getenv("SERVER_TOKEN"),
        client_host=os.getenv("CLIENT_HOST"),
        client_token=os.getenv("CLIENT_TOKEN"),
        command_parser=command_parser,
        white_list=list(map(int, os.getenv("WHITELIST").split(","))),
    )

    asyncio.run(adap.run())


if __name__ == "__main__":
    main()
