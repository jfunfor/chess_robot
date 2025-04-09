import uuid
from enum import Enum
import chess


class Colors(Enum):
    WHITE = 0
    BLACK = 1


class Player:
    def __init__(self, websocket, figures_color):
        self.websocket = websocket
        self.figures_color = figures_color


class Session:
    def __init__(self):
        self.id = uuid.uuid1()
        self.active_players = 0
        self.players = []
        self.is_active = False
        self.current_player = None
        self.chess = chess
        self.board = self.chess.Board()#"8/8/8/8/2P5/8/Q7/8 w - - 0 1"

    def add_player(self, websocket):
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
        player = next(
            (player
             for player in self.players
             if self.players.websocket == websocket),
            None
        )
        self.players[self.players.index(player)] = None
        self.active_players -= 1
        self.is_active = False

    def return_board(self):
        return self.board.fen()

    def make_move(self, move):
        try:
            self.board.push_uci(move)
            return True
        except ValueError:
            return False

    def check_gameover(self):
        return self.board.is_game_over()
    
    def check_square(self,pos):
        if self.board.piece_at(chess.parse_square(pos)) != None:
            return  self.board.piece_at(chess.parse_square(pos))
        else:
            return None
        
    def get_remaining_pieces_with_squares(self):
    
        remaining_pieces = []
    
        for square in chess.SQUARES:
            piece = self.board.piece_at(square)
            if piece is not None:
                square_name = chess.square_name(square)  # например, "e4"
                piece_symbol = piece.symbol()    # например, "P"
                remaining_pieces.append((square_name, piece_symbol))
    
        return remaining_pieces
        