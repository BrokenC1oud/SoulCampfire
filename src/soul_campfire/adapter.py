import asyncio
from asyncio import Queue

from aiohttp import web

from .command import CommandParser
from .onebot.http_ser import OneBotEvent
from .onebot.http_ser import HttpServer
from .onebot.http_cli import HttpClient


class Adapter:
    def __init__(
            self, server_port: int, server_token: str, client_host: str, client_token: str,
            command_parser: CommandParser, white_list: list[int]
    ):
        self.site = None
        self.message_queue: Queue[OneBotEvent] = asyncio.Queue()

        self.http_server = HttpServer(
            port=server_port, token=server_token, message_queue=self.message_queue
        )
        self.http_client = HttpClient(host=client_host, token=client_token)
        self.command_parser = command_parser
        self.white_list = white_list

    async def setup_server(self):
        runner = web.AppRunner(self.http_server.app)
        await runner.setup()
        self.site = web.TCPSite(runner, "0.0.0.0", self.http_server.port)

    async def worker(self):
        while True:
            while message := await self.message_queue.get():
                print("received msg: ", message.raw_message)
                if message.raw_message.startswith("/") and message.group_id in self.white_list:
                    command = message.raw_message[1:]
                    response = self.command_parser.execute(command, message)
                    if response is not None:
                        self.http_client.send_group_msg(message.group_id, f"[CQ:reply,id={message.message_id}]{response}")

    async def run(self):
        await self.setup_server()

        await asyncio.gather(self.worker(), self.site.start())
