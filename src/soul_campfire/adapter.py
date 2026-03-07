import asyncio
from aiohttp import web

from .onebot.http_ser import HttpServer
from .onebot.http_cli import HttpClient


class Adapter:
    def __init__(
        self, server_port: int, server_token: str, client_host: str, client_token: str
    ):
        self.message_queue = asyncio.Queue()

        self.http_server = HttpServer(
            port=server_port, token=server_token, message_queue=self.message_queue
        )
        self.http_client = HttpClient(host=client_host, token=client_token)

    async def setup_server(self):
        runner = web.AppRunner(self.http_server.app)
        await runner.setup()
        self.site = web.TCPSite(runner, "0.0.0.0", self.http_server.port)

    async def worker(self):
        while True:
            await asyncio.sleep(1)

    async def run(self):
        await self.setup_server()

        await asyncio.gather(self.worker(), self.site.start())
