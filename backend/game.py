import uuid
from enum import Enum
import chess


class Colors(Enum):
    WHITE = 0
    BLACK = 1


class Player:
    def __init__(self, websocket, figures_color):
        """
        Инициализирует объект игрока.
        
        Параметры:
            websocket (WebSocket): соединение с клиентом
            figures_color (Colors): цвет фигур игрока
        """
        self.websocket = websocket
        self.figures_color = figures_color


class Session:
    def __init__(self):
        """Инициализирует новую игровую сессию со сброшенными параметрами."""
        self.reset()

    def add_player(self, websocket=None):
        """
        Добавляет игрока в сессию.
        
        Параметры:
            websocket (WebSocket): соединение с клиентом
        """
        if not self.active_players:
            new_client = Player(
                websocket=websocket,
                figures_color=Colors.WHITE
            )
            self.current_player = 0
        else:
            new_client = Player(
                websocket=websocket,
                figures_color=Colors.BLACK
            )
            self.is_active = True

        self.players.append(new_client)
        self.active_players += 1

    def delete_player(self, websocket):
        """
        Удаляет игрока из сессии.
        
        Параметры:
            websocket (WebSocket): соединение удаляемого игрока
        """
        player = next(
            (player
             for player in self.players
             if player is not None
             and player.websocket == websocket),
            None
        )
        self.players[self.players.index(player)] = None
        self.active_players -= 1
        self.is_active = False

    def reset(self):
        """Сбрасывает состояние сессии к начальным значениям."""
        self.active_players = 0
        self.players = []
        self.is_active = False
        self.current_player = None
        self.chess = chess
        self.board = self.chess.Board()

    def return_board(self):
        """
        Возвращает текущее состояние доски в FEN-нотации.
        
        Возвращает:
            str: строка FEN
        """
        return self.board.fen()

    def make_move(self, move):
        """
        Выполняет ход на доске.
        
        Параметры:
            move (str): ход в UCI-формате (например, "e2e4")
        
        Возвращает:
            bool: True если ход валиден, False в противном случае
        """
        try:
            self.board.push_uci(move)
            return True
        except ValueError:
            return False

    def check_gameover(self):
        """
        Проверяет завершение игры.
        
        Возвращает:
            bool: True если игра завершена
        """

        return self.board.is_game_over()
    
    def check_square(self,pos):
        """
        Проверяет наличие фигуры на указанной клетке.
        
        Параметры:
            pos (str): координаты клетки (например, "e4")
        
        Возвращает:
            chess.Piece | None: объект фигуры или None
        """
        if self.board.piece_at(chess.parse_square(pos)) != None:
            return  self.board.piece_at(chess.parse_square(pos))
        else:
            return None
        