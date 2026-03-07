import os

import asyncio
import dotenv

from soul_campfire.adapter import Adapter

def main():
    dotenv.load_dotenv()
    
    adapter = Adapter(
        server_port=os.getenv("SERVER_PORT"), 
        server_token=os.getenv("SERVER_TOKEN"), 
        client_host=os.getenv("CLIENT_HOST"), 
        client_token=os.getenv("CLIENT_TOKEN")
    )

    asyncio.run(adapter.run())

if __name__ == "__main__":
    main()