from flask import Flask, request
from flask_socketio import SocketIO, emit
import chess

app = Flask(__name__)
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app, cors_allowed_origins="*")

# Создаем начальную шахматную доску
board = chess.Board()

@socketio.on('connect')
def handle_connect():
    emit('server_response', {"status": "your_turn"})

@socketio.on('client_request')
def handle_client_request(data):
    global board
    action = data.get('action')

    if action == 'move':
        pos_start = data.get('pos_start')
        pos_end = data.get('pos_end')

        try:
            move = chess.Move.from_uci(f"{pos_start}{pos_end}")
            if move in board.legal_moves:
                board.push(move)
                emit('server_response', {"status": "success"})
                emit('server_response', {"state": board.fen()})
            else:
                emit('server_response', {"status": "error", "description": "Illegal move"})
        except ValueError:
            emit('server_response', {"status": "error", "description": "Invalid move format"})

    elif action == 'board_state':
        emit('server_response', {"state": board.fen()})

    elif action == 'reset_board':
        # Сбрасываем доску в начальное состояние
        board.reset()
        emit('server_response', {"status": "success", "state": board.fen()})

if __name__ == '__main__':
    socketio.run(app, debug=True)
