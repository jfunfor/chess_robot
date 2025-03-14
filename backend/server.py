import asyncio
import websockets
import socket
import redis
import uuid
import json

LETTERS = "ABCDEFGH"

def change_format_cell(cell):
    return int(cell[1]) * 8 - (8 - (int(LETTERS.index(cell[0])) + 1))

def robot_request(board_from, pos_from, board_to, pos_to):
    return f"Move,{board_from},{pos_from},{board_to},{pos_to}\r\n" 

class RedisConnector:
    def __init__(self, host='localhost', port=6379, db=0):
        self.host = host
        self.port = port
        self.db = db
        self.client = None

    def connect(self):
        if not self.client:
            try:
                self.client = redis.Redis(host=self.host, port=self.port, db=self.db)
            except redis.exceptions.RedisError as e:
                print(f"Ошибка подключения к базе данных: {e}")

    def disconnect(self):
        if self.client:
            self.client.close()
            self.client = None

    def execute(self, command, *args):
        if not self.client:
            self.connect()
        return self.client.execute_command(command, *args)
    


class RobotConnector:
    def __init__(self, host='localhost', port=12345):
        self.host = host
        self.port = port
        self.socket = None

    def connect(self):
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.host, self.port))
            print(f"Connected to robot at {self.host}:{self.port}")
        except ConnectionRefusedError:
            print(f"Connection to robot at {self.host}:{self.port} refused.")
            exit(1)

    def send_and_receive(self, message):
        try:
            self.socket.sendall(message.encode())
            response = self.socket.recv(1024).decode()
            return response
        except Exception as e:
            print(f"Error communicating with robot: {e}")
            return None

    def close(self):
        if self.socket:
            self.socket.close()
            print("Connection to robot closed")

# WebSocket-сервер для клиентов
class WebSocketServer:
    def __init__(self, robot_connection: RobotConnector, redis_connection: RedisConnector):
        self.robot_connection = robot_connection
        self.redis_connection = redis_connection
        self.redis_connection.connect()
        self.active_clients = 0

    async def handle_client(self, websocket):
        while True:
            try:
                message_str = await websocket.recv()
                message = json.loads(message_str)
                print(f"Received message from client: {message}")
                action = message['action']
                robot_response = None
                response = None
                if not action:
                    response = {"status":"error"}
                else:
                    if action == 'move':
                        pos_start, pos_end = message['pos_start'], message['pos_end']
                        if not pos_start or not pos_end:
                            response = {"status":"error"}
                        else:
                            robot_response = self.robot_connection.send_and_receive(robot_request(1, change_format_cell(pos_start),
                                                                                                  1, change_format_cell(pos_end)))
                            response = {"status":"success"} if robot_response == 'Done' else {"status":"error"}
                # тут доделать остальные запросы
                #
                #
                #
                print(response)
                await websocket.send(json.dumps(response))
                if robot_response:
                    self.redis_connection.execute('RPUSH', 'turns', f"{pos_start}-{pos_end}")
            except websockets.ConnectionClosed:
                print("Client disconnected")
                self.active_clients = 0
                self.redis_connection.disconnect()
                self.robot_connection.close()
                break

    async def run(self):
        self.robot_connection.connect()
        async with websockets.serve(self.handle_client, "localhost", 8765):
            print("WebSocket-сервер запущен на порту 8765")
            await asyncio.Future()  # run forever

if __name__ == "__main__":
    robot_conn = RobotConnector()
    redis_conn = RedisConnector()
    ws_server = WebSocketServer(robot_conn, redis_conn)
    asyncio.run(ws_server.run())