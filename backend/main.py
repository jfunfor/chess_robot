import asyncio

from server import WebSocketServer


if __name__ == "__main__":
    ws_server = WebSocketServer()
    asyncio.run(ws_server.run())