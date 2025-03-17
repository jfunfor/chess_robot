import asyncio
import websockets
import socket
import redis
import json
import time


# import aiodebug.log_slow_callbacks
# import logging
# logging.basicConfig(
#     level=logging.DEBUG,
#     format='%(asctime)s - %(levelname)s - %(message)s'
# )

# def log_slow_handler(task, duration):
#     logging.debug(f'Task blocked async loop for too long. Task {task} Duration {duration}')

# aiodebug.log_slow_callbacks.enable(0.001, on_slow_callback=log_slow_handler)


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
                self.client.ping()
                print(f"Connected to Redis db at {self.host}:{self.port}")
            except Exception as e:
                print(f"Ошибка подключения к базе данных: {e}")
                exit(1)

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

class WebSocketServer:
    def __init__(self, robot_connection: RobotConnector, redis_connection: RedisConnector):
        self.robot_connection = robot_connection
        self.redis_connection = redis_connection
        self.active_clients = 0
        self.clients = []
        self.current_turn = 0
        self.is_game_start = False

    async def handle_client(self, websocket):
        if self.active_clients >= 2:
            await websocket.send(json.dumps({"message":"session is full"}))
            return

        self.active_clients += 1
        self.clients.append(websocket)

        if self.active_clients == 2:
            self.is_game_start = True
            await self.clients[self.current_turn].send(json.dumps({"status": "your_turn"}))

        while True:
            if self.is_game_start:
                if self.clients[self.current_turn] is websocket:
                    try:
                        message_str = await websocket.recv()
                        message = json.loads(message_str)
                        print(f"Received message from client: {message}")
                        action = message.get('action')
                        robot_response = None
                        response = None
                        if action is None:
                            response = {"status":"error"}
                        else:
                            if action == 'move':
                                pos_start, pos_end = message.get('pos_start'), message.get('pos_end')
                                if pos_start is None or pos_end is None:
                                    response = {"status":"error"}
                                else:
                                    robot_response = self.robot_connection.send_and_receive(robot_request(1, change_format_cell(pos_start),
                                                                                                        1, change_format_cell(pos_end)))
                                    response = {"status":"success"} if robot_response == 'Done' else {"status":"error"}
                                    self.current_turn = 1 - self.current_turn
                                    #Тут отправить состояние доски второму игроку
                                    await self.clients[self.current_turn].send(json.dumps({"status":"your_turn"}))
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
                        self.is_game_start = False
                        self.redis_connection.disconnect()
                        self.robot_connection.close()
                        break
            await asyncio.sleep(0)

    async def run(self):
        self.robot_connection.connect()
        self.redis_connection.connect()
        async with websockets.serve(self.handle_client, "localhost", 8765):
            print("WebSocket-сервер запущен на порту 8765")
            await asyncio.Future()  # run forever

if __name__ == "__main__":
    robot_conn = RobotConnector()
    redis_conn = RedisConnector()
    ws_server = WebSocketServer(robot_conn, redis_conn)
    asyncio.run(ws_server.run())