import asyncio
import json
import chess
from websockets.server import serve

# Глобальное хранилище для игр
active_games = {
    "default": {
        "board": chess.Board(),
        "connections": set(),
        "players": {}  # Список игроков с их цветами
    }
}


async def chess_game_handler(websocket):
    game_id = "default"
    game = active_games[game_id]
    board = game["board"]

    # Назначаем цвет игроку
    if len(game["players"]) == 0:
        color = "w"  # Первый игрок — белые
    elif len(game["players"]) == 1:
        color = "b"  # Второй игрок — черные
    else:
        await websocket.send(json.dumps({
            "type": "error",
            "error": {"message": "Игра уже началась"}
        }))
        return

    # Добавляем игрока в список
    game["connections"].add(websocket)
    game["players"][websocket] = color

    try:
        # Отправляем начальное состояние и назначенный цвет игроку
        await websocket.send(json.dumps({
            "type": "init_game",
            "data": {"color": color}
        }))

        async for message in websocket:
            try:
                data = json.loads(message)
                message_type = data.get('type')

                if message_type == 'make_move':
                    pos_start = data['data']['pos_start']
                    pos_end = data['data']['pos_end']

                    try:
                        move = chess.Move.from_uci(f"{pos_start}{pos_end}")
                        if move in board.legal_moves:
                            board.push(move)
                            response = {
                                "type": "update_game_state",
                                "data": {
                                    "board_state": {"fen": board.fen()},
                                    "player_color": "b" if board.turn else "w"
                                }
                            }

                            # Отправляем обновление всем подключенным клиентам
                            for client in game["connections"]:
                                await client.send(json.dumps(response))
                        else:
                            await websocket.send(json.dumps({
                                "type": "error",
                                "error": {"message": "Illegal move"}
                            }))
                    except ValueError:
                        await websocket.send(json.dumps({
                            "type": "error",
                            "error": {"message": "Invalid move format"}
                        }))

                elif message_type == 'get_board_state':
                    await websocket.send(json.dumps({
                        "type": "update_game_state",
                        "data": {
                            "board_state": {"fen": board.fen()},
                            "player_color": "b" if board.turn else "w"
                        }
                    }))

                elif message_type == 'reset_board':
                    board.reset()
                    response = {
                        "type": "update_game_state",
                        "data": {
                            "board_state": {"fen": board.fen()},
                            "player_color": "w"
                        }
                    }
                    # Отправляем всем клиентам
                    for client in game["connections"]:
                        await client.send(json.dumps(response))

            except json.JSONDecodeError:
                await websocket.send(json.dumps({
                    "type": "error",
                    "error": {"message": "Invalid JSON format"}
                }))
    finally:
        # Удаляем подключение при отключении клиента
        game["connections"].remove(websocket)
        del game["players"][websocket]


async def main():
    # Запускаем WebSocket-сервер
    async with serve(chess_game_handler, "localhost", 8000):
        print("WebSocket server started at ws://localhost:8000")
        await asyncio.Future()  # Бесконечное ожидание


if __name__ == "__main__":
    asyncio.run(main())
