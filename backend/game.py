import uuid
from enum import Enum


class Colors(Enum):
    WHITE = 0
    BLACK = 1


class Player:
    def __init__(self, websocket, figures_color):
        self.websocket = websocket
        self.figures_color = figures_color

#Прописать логику шахматного поля
class Session:
    def __init__(self):
        self.id = uuid.uuid1()
        self.active_players = 0
        self.players = []
        self.is_active = False
        self.current_player = None
    
    def add_player(self, websocket):
        if not self.active_players:
            new_client = Player(websocket=websocket, figures_color=Colors.WHITE)
            self.current_player = 0
        else:
            new_client = Player(websocket=websocket, figures_color=Colors.BLACK)
            self.is_active = True
        
        self.players.append(new_client)
        self.active_players += 1

    def delete_player(self, websocket):
        player = next((player for player in self.players if self.players.websocket == websocket), None)
        self.players[self.players.index(player)] = None
        self.active_players -= 1
        self.is_active = False


    