import datetime
import enum

from sqlalchemy import create_engine, ForeignKey
from sqlalchemy.orm import declarative_base, Mapped, mapped_column, sessionmaker

engine = create_engine('sqlite:///soul_campfire.db')

Base = declarative_base()


class Trait(enum.Enum):
    """
    灵根
    """
    metal = "金"
    wood = "木"
    water = "水"
    fire = "火"
    dust = "土"


class School(enum.Enum):
    """
    宗门
    """
    star_palace = "星宫"
    yellow_maple_valley = "黄枫谷"
    acacia_sect = "合欢宗"
    black_demon = "黑煞教"
    all_souls_sect = "万灵宗"
    supreme_one_sect = "太一宗"
    rogue = "散修"


class User(Base):
    __tablename__ = "user"

    id: Mapped[int] = mapped_column(primary_key=True)
    cultivation: Mapped[int]
    trait: Mapped[Trait]
    school: Mapped[School]


class Practice(Base):
    __tablename__ = "practice"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    user: Mapped[int] = mapped_column(ForeignKey("user.id"))
    cultivation: Mapped[int]
    time: Mapped[datetime.datetime]
    cooldown: Mapped[int]


Base.metadata.create_all(engine)

Session = sessionmaker(bind=engine)
