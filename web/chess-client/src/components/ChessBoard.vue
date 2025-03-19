<template>
  <div>
    <h2>Шахматная доска</h2>
    <div id="board" style="width: 400px; margin-bottom: 20px;"></div>
    <div>
      <input v-model="posStart" placeholder="Начальная позиция (например, e2)" />
      <input v-model="posEnd" placeholder="Конечная позиция (например, e4)" />
      <button @click="makeMove">Сделать ход</button>
      <button @click="getBoardState">Обновить доску</button>
      <button @click="resetBoard">Обнулить доску</button> <!-- Новая кнопка -->
    </div>

    <div v-if="serverMessage">
      <h3>Ответ сервера:</h3>
      <pre>{{ serverMessage }}</pre>
    </div>
  </div>
</template>

<script>
import { io } from 'socket.io-client';
import Chessboard from 'chessboardjs';
import { Chess } from 'chess.js';

export default {
  data() {
    return {
      socket: null,
      board: null,
      game: new Chess(), // Создаем объект игры
      posStart: '',
      posEnd: '',
      serverMessage: null,
    };
  },
  mounted() {
    this.socket = io('http://localhost:5000');

    this.socket.on('connect', () => {
      console.log('Connected to server');
    });

    this.socket.on('server_response', (data) => {
      this.serverMessage = JSON.stringify(data, null, 2);

      // Если сервер прислал новое состояние доски (FEN), обновляем её
      if (data.state) {
        this.board.position(data.state.split(' ')[0]); // Берем только первую часть FEN для chessboard.js
        this.game.load(data.state); // Загружаем полный FEN в chess.js
      }
    });

    this.socket.on('disconnect', () => {
      console.log('Disconnected from server');
    });

    this.board = Chessboard('board', {
      position: 'start',
      draggable: true,
      pieceTheme: '/img/chesspieces/wikipedia/{piece}.png',
    });
  },
  methods: {
    makeMove() {
      const move = { from: this.posStart, to: this.posEnd };

      const validMove = this.game.move(move);

      if (validMove) {
        this.socket.emit('client_request', {
          action: 'move',
          pos_start: move.from,
          pos_end: move.to,
        });
      } else {
        alert("Невозможный ход!");
      }
    },
    getBoardState() {
      this.socket.emit('client_request', { action: 'board_state' });
    },
    resetBoard() {
      // Отправляем запрос на сервер для сброса состояния доски
      this.socket.emit('client_request', { action: 'reset_board' });
    },
  },
};
</script>

<style scoped>
input {
  margin-right: 10px;
}
button {
  margin-right: 10px;
}
</style>
