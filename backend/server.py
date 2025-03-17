import asyncio
import websockets
import json

from redis_conn import RedisConnector
from robot_conn import RobotConnector
from game import *

LETTERS = "ABCDEFGH"


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

    async def handle_client(self, websocket):
        if self.session.active_players >= 2:
            await websocket.send(json.dumps({"message":"session is full"}))
            return
        else:
            self.session.add_player(websocket)
        
        if self.session.active_players == 2:
            await self.send_message({"status":"your_turn"}, self.session.players[self.session.current_player].websocket)

        while True:
            if self.session.is_active:
                try:
                    if self.session.players[self.session.current_player].websocket is websocket:
                        message = json.loads(await websocket.recv())
                        print(f"Received message from client: {message}")
                        action = message.get('action')
                        if action is None:
                            raise Exception("The required field action is missing")
                        if action == 'move':
                            pos_start, pos_end = message.get('pos_start'), message.get('pos_end')
                            if pos_start is None or pos_end is None:
                                raise Exception("Mandatory fields pos_start and pos_end are missing")
                            robot_response = self.robot_conn.send_and_receive(robot_request(1, change_format_cell(pos_start),
                                                                                                1, change_format_cell(pos_end)))
                            if robot_response == 'Done':
                                #Сделать ход на доске и разослать состояние
                                await self.send_message({"status":"success"}, self.session.players[self.session.current_player].websocket)
                                self.redis_conn.execute('RPUSH', self.session.players[self.session.current_player].figures_color.name, 
                                                              f"{pos_start}-{pos_end}")
                                self.session.current_player = 1 - self.session.current_player
                                await self.send_message({"status":"your_turn"}, self.session.players[self.session.current_player].websocket)
                            else:
                                raise Exception("The robot failed to make a move")
                        elif action == 'board_state':
                            pass



                except websockets.ConnectionClosed:
                        print("Client disconnected")
                        self.session.delete_player(websocket)
                        self.session.is_active = False
                except Exception as e:
                    await self.send_message({"status":"error", "description":e.args[0]}, websocket)
            await asyncio.sleep(0)

    async def run(self):
        self.robot_conn.connect()
        self.redis_conn.connect()
        async with websockets.serve(self.handle_client, "localhost", 8765):
            print("WebSocket-сервер запущен на порту 8765")
            await asyncio.Future() 
