import asyncio
import websockets
import json

from redis_conn import RedisConnector
from robot_conn import RobotConnector
from game import (
    Session,
    Colors
)

LETTERS = "abcdefgh"


def change_format_cell(cell):
    return int(cell[1]) * 8 - (8 - (int(LETTERS.index(cell[0])) + 1))


def robot_request(board_from, pos_from, board_to, pos_to):
    return f"Move,{board_from},{pos_from},{board_to},{pos_to}\r\n"


class WebSocketServer:
    def __init__(self):
        self.robot_conn = RobotConnector()
        self.redis_conn = RedisConnector()
        self.session = Session()

    async def send_message(self, message, websocket):
        await websocket.send(json.dumps(message))

    async def broadcast(self, message):
        for connection in self.session.players:
            await self.send_message(message, connection.websocket)

    async def handle_message(self, message, websocket):
        action = message.get('type')
        if action is None:
            raise Exception("The required field action is missing")

        if action == 'make_move':
            await self.handle_move(message, websocket)
        elif action == 'get_board_state':
            await self.handle_board_state(websocket)
        else:
            raise Exception('Invalid type')

    async def handle_move(self, message, websocket):
        data = message.get('data')
        if data is None:
            raise Exception("The required field action is missing")
        pos_start = data.get('pos_start')
        pos_end = data.get('pos_end')
        if pos_start is None or pos_end is None:
            raise Exception(
                "Mandatory fields pos_start and pos_end are missing"
            )

        if not self.session.make_move(pos_start+pos_end):
            raise Exception(
                "Invalid fields pos_start and pos_end. Please try again."
            )

        robot_response = self.robot_conn.send_and_receive(
            robot_request(
                1,
                change_format_cell(pos_start),
                1,
                change_format_cell(pos_end)
            )
        )
        if robot_response == 'Done':
            await self.broadcast_success_move()
        else:
            raise Exception("The robot failed to make a move")

        self.redis_conn.execute(
            'RPUSH',
            self.session.players[
                self.session.current_player
            ].figures_color.name,
            f"{pos_start}-{pos_end}"
        )
        self.session.current_player = 1 - self.session.current_player

    async def handle_board_state(self, websocket):
        curr_player_color = self.session.players[
                self.session.current_player
            ].figures_color
        player_color = 'b' if curr_player_color == Colors.BLACK else 'w'
        message = {
            "type": "board_state",
            "data": {
                "board_state": {
                    "fen": self.session.return_board()
                },
                "player_color": player_color
            }
        }
        await self.send_message(message, websocket)

    async def broadcast_success_move(self):
        curr_player_color = self.session.players[
                self.session.current_player
            ].figures_color
        player_color = 'w' if curr_player_color == Colors.BLACK else 'b'
        message = {
            "type": "update_game_state",
            "data": {
                "board_state": {
                    "fen": self.session.return_board()
                },
                "player_color": player_color
            }
        }
        await self.broadcast(message)

    async def init_game(self):
        def get_init_message(color):
            return {
                "type": "init_game",
                "data": {
                    "color": color
                }
            }
        for connection in self.session.players:
            if connection.figures_color == Colors.WHITE:
                await self.send_message(
                    get_init_message('w'),
                    connection.websocket
                )
            else:
                await self.send_message(
                    get_init_message('b'),
                    connection.websocket
                )

    async def handle_client(self, websocket):
        if self.session.active_players >= 2:
            await websocket.send(json.dumps({"message": "session is full"}))
            return
        else:
            self.session.add_player(websocket)

        if self.session.is_active:
            await self.init_game()

        while True:
            if self.session.is_active:
                try:
                    if self.session.players[
                        self.session.current_player
                    ].websocket is websocket:
                        message = json.loads(await websocket.recv())
                        print(f"Received message from client: {message}")
                        await self.handle_message(message, websocket)
                except websockets.ConnectionClosed:
                    print("Client disconnected")
                    self.session.delete_player(websocket)
                    self.session.is_active = False
                except Exception as e:
                    await self.send_message(
                        {
                            "type": "error",
                            "error": {
                                "message": e.args[0]
                            }
                        },
                        websocket
                    )
            await asyncio.sleep(0)

    async def run(self):
        self.robot_conn.connect()
        self.redis_conn.connect()
        async with websockets.serve(self.handle_client, "localhost", 8765):
            print("WebSocket-сервер запущен на порту 8765")
            await asyncio.Future()
