import asyncio
import websockets
import json

import chess
from itertools import chain, zip_longest
from redis_conn import RedisConnector
from robot_conn import RobotConnector
from game import (
    Session,
    Colors
)

LETTERS = "abcdefgh"

pos_board_2 = 0

def change_format_cell(cell):
    return int(cell[1]) * 8 - (8 - (int(LETTERS.index(cell[0])) + 1))

def change_format_cell_original(pos):
      if 1 <= pos <= 64:  # Проверяем, что число в допустимом диапазоне
            column = LETTERS[(pos - 1) % 8]  # Находим столбец
            row = (pos - 1) // 8 + 1  # Находим строку
            return f"{column}{row}"
      
def robot_request(board_from, pos_from, board_to, pos_to):
    return f"Move,{board_from},{pos_from},{board_to},{pos_to}\r\n"

def decode_redis(data):
    return data.decode("utf-8")

def return_piece(square,board: chess.Board,robot,piece_positions): #возврат фигуры на свое место

    current_square = square[0]
    figure = square[1]
    Board = 2

    if square[0][0:7] == "Board_2":#проверка на то что клетка со 2 доски
        current_square = None
        square_board_2 = square[0][7:len(square[0])]
        Board = 1

    flag = False

    for square in piece_positions[figure]:#если фугура стоит на каком либо месте из своих возможных
        if current_square == square:
            flag = True

        if flag == True:
            break

        
        
    
    if flag == False:#идем сюда в том случае если фигура не стоит ни на каком-либо своем месте
        for square in piece_positions[figure]:
            flag = False
            piece = board.piece_at(change_format_cell(square)-1) # проверка клетки на наличие какой либо фигуры
        #проверяем можем ли мы поставить фигуру на клетку начинающуюю с начала списка

            #если там другая фигура и не того же типа убираем ее на свое место
            if piece != None and piece.symbol() != figure:
                square = (square,piece.symbol())
                return_piece(square,board,robot,piece_positions)

            
            #если там никого нет, ставим
            if piece == None:
                if current_square != None:#если клетка не находиться на 2 доске
                    board.remove_piece_at(change_format_cell(current_square)-1) #удаляем фигуру в логике в доске 2
                else:
                    current_square = square_board_2


                board.set_piece_at(change_format_cell(square)-1,chess.Piece.from_symbol(figure)) # и добавляем ее

                robot_response = robot.send_and_receive( #переставляем фигуру на 1 доске
                robot_request(
                    Board,
                    change_format_cell(current_square),
                    2,
                    change_format_cell(square)
                    )
                )

                

                flag = True

            if flag == True:#установили фигуру на свое место
                break

def get_remaining_pieces_with_squares(board: chess.Board):#расположение фигур на доске
    
        remaining_pieces = []
    
        for square in chess.SQUARES:
            piece = board.piece_at(square)
            if piece is not None:
                square_name = chess.square_name(square)  # например, "e4"
                piece_symbol = piece.symbol()    # например, "P"
                remaining_pieces.append((square_name, piece_symbol))
    
        return remaining_pieces

def return_all_pieces_on_them_places(board,robot,piece_positions):#возврат фигур на свои места 
    remaining_piece = get_remaining_pieces_with_squares(board)
    
    for square in remaining_piece:
        return_piece(square,board,robot,piece_positions)
        remaining_piece = get_remaining_pieces_with_squares(board)
    
def return_to_current_board(Move_w,Move_b,board : chess.Board):# приход к текущему состоянию доски

    Move_w = list(reversed([move for move in Move_w if int(move[-1]) == 0]))
    Move_b = list(reversed([move for move in Move_b if int(move[-1]) == 0]))


    for w,b in zip_longest(Move_w,Move_b): #все ходы, чтобы прийти к текущему состоянию доски
        if w != None:
            board.push_uci(w[0:2]+w[3:5])

        if b!= None:
            board.push_uci(b[0:2]+b[3:5])
    
def return_piece_from_2_to_1(board: chess.Board,robot,piece_positions,dataBase): #возврат фигуры со 2 доски на 1 доску на свои места
    dead_pieces_white = [piece for piece in list(map(decode_redis,dataBase.lrange("WHITE",0,-1))) if int(piece[-1]) == 1]
    dead_pieces_black = [piece for piece in list(map(decode_redis,dataBase.lrange("BLACK",0,-1))) if int(piece[-1]) == 1]

    for piece in dead_pieces_white:
        square = [f"Board_2{piece[3:5]}",piece[len(piece)-3]]
        return_piece(square,board,robot,piece_positions)
    
    for piece in dead_pieces_black:
        square = [f"Board_2{piece[3:5]}",piece[len(piece)-3]]
        return_piece(square,board,robot,piece_positions)

def return_board_to_original(robot): #возврат доски в исходное состояние
    redis = RedisConnector()# подкл к БД
    redis.connect()
    dataBase = redis.client

    #robot = RobotConnector()# подкл к роботу
    #robot.connect()

    itemsWhite = list(reversed(list(map(decode_redis,dataBase.lrange("WHITE",0,-1)))))
    itemsBlack = list(reversed(list(map(decode_redis,dataBase.lrange("BLACK",0,-1)))))

    
    piece_positions = { # клетки на которых стоят фигуры
    # Белые фигуры
    "P": ["a2", "b2", "c2", "d2", "e2", "f2", "g2", "h2"],  # Пешки
    "N": ["b1", "g1"],  # Кони
    "B": ["c1", "f1"],  # Слоны
    "R": ["a1", "h1"],  # Ладьи
    "Q": ["d1"],  # Ферзь
    "K": ["e1"],  # Король
    
    # Черные фигуры (строчные)
    "p": ["a7", "b7", "c7", "d7", "e7", "f7", "g7", "h7"],  # Пешки
    "n": ["b8", "g8"],  # Кони
    "b": ["c8", "f8"],  # Слоны
    "r": ["a8", "h8"],  # Ладьи
    "q": ["d8"],  # Ферзь
    "k": ["e8"],  # Король
    }

    board = chess.Board()

    return_to_current_board(itemsWhite,itemsBlack,board) 

    return_all_pieces_on_them_places(board,robot,piece_positions)

    return_piece_from_2_to_1(board,robot,piece_positions,dataBase)


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
        
        piece_simbol_start = self.session.board.piece_at(change_format_cell(pos_start)-1).symbol()
        print(piece_simbol_start)
        

        if  self.session.check_square(pos_end) != None: #проверка на занятость клетки фигурой
            cell_occupied = True
            piece_simbol_end = self.session.board.piece_at(change_format_cell(pos_end)-1).symbol()
        else:
            cell_occupied = False
        
    
        if not self.session.make_move(pos_start+pos_end):
            raise Exception(
                "Invalid fields pos_start and pos_end. Please try again."
            )
       
        if cell_occupied: 
            global pos_board_2 
            pos_board_2 = pos_board_2+1
            robot_response = self.robot_conn.send_and_receive( #убираем фигуру на 1 доску
                robot_request(
                    2,
                    change_format_cell(pos_end),
                    1,
                    pos_board_2
                )
            )
             
            #await self.broadcast_success_move()
        
            color = self.session.players[
                1 - self.session.current_player
            ].figures_color.name
            self.redis_conn.execute( # данные, которые хранятся в БД, что фигура была убрана с доски
                'RPUSH',
                self.session.players[
                    1 - self.session.current_player
                ].figures_color.name,
                f"{pos_end}-{change_format_cell_original(pos_board_2)}-{color}-{piece_simbol_end}-1"
            )
        
        robot_response = self.robot_conn.send_and_receive(
            robot_request(
                2,
                change_format_cell(pos_start),
                2,
                change_format_cell(pos_end)
            )
        )
        print(robot_response)

        color = self.session.players[
                self.session.current_player
            ].figures_color.name
        self.redis_conn.execute(
            'RPUSH',
            self.session.players[
                self.session.current_player
            ].figures_color.name,
            f"{pos_start}-{pos_end}-{color}-{piece_simbol_start}-0"
        )
        await self.broadcast_success_move()
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
            self.robot_conn.connect()
            self.redis_conn.connect()
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
                    return_board_to_original(self.robot_conn)
                    #asyncio.create_task(self.async_return_board())
                    self.session.delete_player(websocket)
                    if self.redis_conn:
                        self.redis_conn.execute("FLUSHALL")
                        self.redis_conn.disconnect()
                    if self.robot_conn:
                        self.robot_conn.close()
                    remaining_clients = [
                        player.websocket 
                        for player in self.session.players 
                        if player is not None 
                        and player.websocket != websocket 
                        and player.websocket.state == websockets.protocol.State.OPEN
                    ]
                    for client in remaining_clients:
                        await client.close(code=1001, reason="Partner disconnected")
                        self.session.delete_player(client)
                    self.session.reset()

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
            await asyncio.sleep(0.1)

    async def async_return_board(self):
        loop = asyncio.get_running_loop()
        await loop.run_in_executor(
            None, 
            return_board_to_original, 
            self.robot_conn
        )

    async def run(self):
        async with websockets.serve(
            self.handle_client,
            "0.0.0.0",
            8765,
            ping_interval=10,
            ping_timeout=5
        ):
            print("WebSocket-сервер запущен на порту 8765")
            await asyncio.Future()
