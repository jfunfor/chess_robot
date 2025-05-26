<template>
  <div class="chess-container">
    <!-- Экран ожидания второго игрока -->
    <div v-if="gameStatus === 'waiting'" class="waiting-screen">
      <h1>Ожидание второго игрока...</h1>
      <div class="spinner"></div>
      <p>Как только подключится второй игрок, игра начнется автоматически</p>
    </div>

    <!-- Основной экран игры -->
    <div v-else-if="gameStatus === 'playing'">
      <!-- Шапка с информацией о текущем ходе -->
      <div class="header">
        <h1>Шахматная игра</h1>
        <div class="current-turn">
          <div class="turn-indicator" :class="game.turn() === 'w' ? 'white-turn' : 'black-turn'"></div>
          <span>{{ game.turn() === 'w' ? 'Ход белых' : 'Ход черных' }}</span>
        </div>
      </div>

      <div class="game-area">
        <!-- Левая панель: срубленные черные фигуры -->
        <div class="captured-pieces black-captured">
          <div v-for="(piece, index) in capturedPieces.b" :key="'b'+index" class="captured-piece">
            <img :src="`/img/chesspieces/wikipedia/${piece}.png`" :alt="piece" />
          </div>
        </div>

        <!-- Центральная часть: шахматная доска -->
        <div class="board-container">
          <div id="board" class="chess-board" @click="removeSelection"></div>
          <div class="controls">
            <button @click="updateBoardState" class="update-button">Обновить доску</button>
            <div class="player-info">
              Вы играете: <span :class="playerColor === 'w' ? 'white-color' : 'black-color'">
                {{ playerColor === 'w' ? 'белыми' : 'черными' }}
              </span>
            </div>
          </div>
        </div>

        <!-- Правая панель: срубленные белые фигуры -->
        <div class="captured-pieces white-captured">
          <div v-for="(piece, index) in capturedPieces.w" :key="'w'+index" class="captured-piece">
            <img :src="`/img/chesspieces/wikipedia/${piece}.png`" :alt="piece" />
          </div>
        </div>
      </div>

      <!-- Нижняя панель: FEN-нотация -->
      <div class="fen-panel">
        <h3>FEN-нотация:</h3>
        <div class="fen-value">{{ currentFen }}</div>
      </div>
    </div>

    <!-- Экран результата игры -->
    <div v-else-if="gameStatus === 'game_over'" class="result-screen">
      <h1>{{ gameResultText }}</h1>
      <div class="result-icon" :class="gameResultClass"></div>
    </div>
  </div>
</template>

<script>
import $ from 'jquery';
import Chessboard from 'chessboardjs';
import { Chess } from 'chess.js';

export default {
  data() {
    return {
      board: null,
      game: new Chess(),
      socket: null,
      playerColor: null,
      currentFen: '',
      selectedSquare: null,
      capturedPieces: {
        w: [], // Срубленные белые фигуры
        b: []  // Срубленные черные фигуры
      },
      gameStatus: 'waiting', // 'waiting', 'playing', 'game_over'
      gameResult: null // 'win', 'lose', 'draw'
    };
  },
  computed: {
    currentTurnText() {
      return this.game.turn() === 'w' ? 'Ход белых' : 'Ход черных';
    },
    gameResultText() {
      if (this.gameResult === 'win') return 'Победа!';
      if (this.gameResult === 'lose') return 'Поражение';
      if (this.gameResult === 'draw') return 'Ничья';
      return 'Игра завершена';
    },
    gameResultClass() {
      if (this.gameResult === 'win') return 'win-icon';
      if (this.gameResult === 'lose') return 'lose-icon';
      if (this.gameResult === 'draw') return 'draw-icon';
      return '';
    }
  },
  mounted() {
    // Инициализация jQuery в глобальном контексте
    window.$ = $;
    window.jQuery = $;

    // Подключение к WebSocket
    this.connectWebSocket();
  },
  methods: {
     connectWebSocket() {
      const wsUrl = `ws://${window.APP_CONFIG.WS_SERVER_IP}:${window.APP_CONFIG.WS_SERVER_PORT}`;
      this.socket = new WebSocket(wsUrl);

      this.socket.onopen = () => {
        console.log('Connected to:', wsUrl);
      };

      this.socket.onmessage = (event) => {
        console.log('Received message:', event.data);
        const data = JSON.parse(event.data);

        if (data.type === 'init_game') {
          this.playerColor = data.data.color;
          console.log(`You are playing as: ${this.playerColor === 'w' ? 'white' : 'black'}`);
          this.gameStatus = 'playing';
          this.$nextTick(() => {
            this.initBoard();
          });
        }
        else if (data.type === 'update_game_state') {
          if (data.data.board_state && data.data.board_state.fen) {
            this.currentFen = data.data.board_state.fen;
            this.game.load(this.currentFen);

            if (this.game.isGameOver()) {
              this.handleGameOver();
            } else {
              if (this.board) {
                this.board.position(this.currentFen);
              }
              this.updateCapturedPieces();
              this.removeSelection();
            }
          }
        }
        else if (data.type === 'game_over') {
          this.handleGameOver(data.data.result);
        }
      };

      this.socket.onclose = () => {
        console.log('Disconnected from WebSocket server');
        // Попытка переподключения через 5 секунд
        setTimeout(() => {
          this.connectWebSocket();
        }, 5000);
      };

      this.socket.onerror = (error) => {
        console.error('WebSocket error:', error);
      };
    },

    initBoard() {
      // Проверяем, существует ли элемент board в DOM
      if (!document.getElementById('board')) {
        console.error('Board element not found in DOM');
        return;
      }

      this.board = Chessboard('board', {
        position: 'start',
        draggable: true,
        pieceTheme: '/img/chesspieces/wikipedia/{piece}.png',
        orientation: this.playerColor === 'w' ? 'white' : 'black',
        onDragStart: this.handleDragStart,
        onDrop: this.handleDrop,
        onSnapEnd: this.onSnapEnd,
        onMouseoverSquare: this.handleMouseoverSquare,
        onMouseoutSquare: this.handleMouseoutSquare
      });

      this.currentFen = this.game.fen();
      this.board.position(this.currentFen);

      // Устанавливаем размеры доски после инициализации
      this.$nextTick(() => {
        const boardElement = document.getElementById('board');
        if (boardElement) {
          boardElement.style.width = '600px';
          boardElement.style.height = '600px';
          if (this.board) {
            this.board.resize();
          }
        }
      });
    },

    handleGameOver(result = null) {
      if (!result) {
        // Определяем результат на основе текущего состояния игры
        if (this.game.isCheckmate()) {
          this.gameResult = this.game.turn() !== this.playerColor ? 'win' : 'lose';
        } else if (this.game.isDraw()) {
          this.gameResult = 'draw';
        }
      } else {
        // Используем результат, присланный сервером
        this.gameResult = result;
      }

      this.gameStatus = 'game_over';
      if (this.board) {
        this.board.position(this.currentFen);
      }
      this.updateCapturedPieces();
    },

    handleDragStart(source, piece) {
      if (this.gameStatus !== 'playing') return false;

      // Проверяем, может ли игрок двигать эту фигуру
      if ((this.playerColor === 'w' && piece.search(/^b/) !== -1) ||
          (this.playerColor === 'b' && piece.search(/^w/) !== -1)) {
        return false;
      }

      // Проверяем, чей сейчас ход
      if ((this.game.turn() === 'w' && this.playerColor === 'b') ||
          (this.game.turn() === 'b' && this.playerColor === 'w')) {
        return false;
      }

      // Запоминаем выбранную клетку
      this.selectedSquare = source;
      return true;
    },

    handleDrop(source, target) {
      // Если фигуру отпустили на той же клетке - просто снимаем выделение
      if (source === target) {
        if (this.selectedSquare === source) {
          this.removeSelection();
        } else {
          this.selectedSquare = source;
          this.highlightPossibleMoves(source);
        }
        return;
      }

      // Проверка валидности хода локально
      const move = this.game.move({
        from: source,
        to: target,
        promotion: 'q'
      });

      // Если ход невалидный, возвращаем фигуру на место
      if (move === null) return 'snapback';

      // Отправляем ход на сервер
      this.socket.send(JSON.stringify({
        type: 'make_move',
        data: {
          pos_start: source,
          pos_end: target
        }
      }));

      // Сбрасываем выбранную клетку
      this.selectedSquare = null;
    },

    onSnapEnd() {
      if (this.board) {
        this.board.position(this.game.fen());
      }
    },

    updateBoardState() {
      if (this.board) {
        this.board.position(this.currentFen);
      }
    },

    resetBoard() {
      this.gameStatus = 'waiting';
      this.gameResult = null;
      this.game = new Chess();
      this.capturedPieces = { w: [], b: [] };
      this.currentFen = this.game.fen();

      if (this.board) {
        this.board.position('start');
      }

      this.socket.send(JSON.stringify({
        type: 'reset_board'
      }));
    },

    highlightPossibleMoves(square) {
      this.removeGreySquares();
      const moves = this.game.moves({
        square: square,
        verbose: true
      });

      if (moves.length === 0) return;

      this.greySquare(square);
      for (const move of moves) {
        this.greySquare(move.to);
      }
    },

    handleMouseoverSquare(square) {
      if (this.selectedSquare) {
        const moves = this.game.moves({
          square: this.selectedSquare,
          verbose: true
        });

        for (const move of moves) {
          if (move.to === square) {
            this.greySquare(move.to);
          }
        }
      } else {
        const moves = this.game.moves({
          square: square,
          verbose: true
        });

        if (moves.length === 0) return;

        this.greySquare(square);
        for (const move of moves) {
          this.greySquare(move.to);
        }
      }
    },

    handleMouseoutSquare() {
      if (!this.selectedSquare) {
        this.removeGreySquares();
      }
    },

    removeSelection() {
      this.selectedSquare = null;
      this.removeGreySquares();
    },

    greySquare(square) {
      const squareEl = document.querySelector(`.square-${square}`);
      if (squareEl) squareEl.style.backgroundColor = '#a9a9a9';
    },

    removeGreySquares() {
      const squares = document.querySelectorAll('.square-55d63');
      squares.forEach((el) => (el.style.backgroundColor = ''));
    },

    updateCapturedPieces() {
      const pieces = this.game.board().flat().filter(Boolean);
      const initialSetup = {
        'w': { 'p': 8, 'r': 2, 'n': 2, 'b': 2, 'q': 1, 'k': 1 },
        'b': { 'p': 8, 'r': 2, 'n': 2, 'b': 2, 'q': 1, 'k': 1 }
      };

      const currentCount = {
        'w': { 'p': 0, 'r': 0, 'n': 0, 'b': 0, 'q': 0, 'k': 0 },
        'b': { 'p': 0, 'r': 0, 'n': 0, 'b': 0, 'q': 0, 'k': 0 }
      };

      pieces.forEach(p => {
        if (p && p.type && p.color) {
          currentCount[p.color][p.type]++;
        }
      });

      this.capturedPieces = { w: [], b: [] };

      Object.keys(initialSetup).forEach(color => {
        Object.keys(initialSetup[color]).forEach(piece => {
          const count = currentCount[color][piece];
          const diff = initialSetup[color][piece] - count;

          for (let i = 0; i < diff; i++) {
            if (color === 'w') {
              this.capturedPieces.w.push(`w${piece}`);
            } else {
              this.capturedPieces.b.push(`b${piece}`);
            }
          }
        });
      });

      this.capturedPieces.w = this.capturedPieces.w.map(p =>
        p[0] + p[1].toUpperCase()
      );
      this.capturedPieces.b = this.capturedPieces.b.map(p =>
        p[0] + p[1].toUpperCase()
      );
    }
  },
  beforeUnmount() {
    if (this.socket) {
      this.socket.close();
    }
  }
};
</script>

<style scoped>
/* Все стили остаются без изменений */
.chess-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
}

.waiting-screen {
  text-align: center;
  padding: 50px;
  background-color: #f9f9f9;
  border-radius: 10px;
  margin-top: 50px;
}

.spinner {
  width: 50px;
  height: 50px;
  border: 5px solid #f3f3f3;
  border-top: 5px solid #3498db;
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 20px auto;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

.result-screen {
  text-align: center;
  padding: 50px;
  background-color: #f9f9f9;
  border-radius: 10px;
  margin-top: 50px;
}

.result-icon {
  width: 100px;
  height: 100px;
  margin: 20px auto;
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
}

.win-icon {
  background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%232ecc71"><path d="M12 2L4 12l8 10 8-10z"/><path d="M7 12l5 5 5-5"/></svg>');
}

.lose-icon {
  background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%23e74c3c"><path d="M12 2L2 22h20L12 2z"/><path d="M12 16h0m-4-4h8"/></svg>');
}

.draw-icon {
  background-image: url('data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="%23f39c12"><path d="M12 2a10 10 0 100 20 10 10 0 000-20zm0 18a8 8 0 110-16 8 8 0 010 16z"/><path d="M8 12h8"/></svg>');
}

.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.current-turn {
  display: flex;
  align-items: center;
  font-size: 18px;
  font-weight: bold;
}

.turn-indicator {
  width: 20px;
  height: 20px;
  border-radius: 50%;
  margin-right: 10px;
}

.white-turn {
  background-color: white;
  border: 1px solid #000;
}

.black-turn {
  background-color: black;
}

.game-area {
  display: flex;
  justify-content: space-between;
  gap: 20px;
  margin-bottom: 20px;
}

.captured-pieces {
  width: 150px;
  min-height: 600px;
  padding: 10px;
  background-color: #f0f0f0;
  border-radius: 5px;
}

.captured-piece {
  display: inline-block;
  margin: 5px;
}

.captured-piece img {
  width: 30px;
  height: 30px;
  margin-left: -15px;
}

.board-container {
  display: flex;
  flex-direction: column;
  align-items: center;
}

.chess-board {
  width: 600px !important;
  height: 600px !important;
  margin-bottom: 20px;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
}

.controls {
  display: flex;
  justify-content: center;
  width: 100%;
  margin-top: 10px;
  gap: 10px;
}

.control-button, .update-button {
  padding: 10px 20px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
}

.control-button:hover, .update-button:hover {
  background-color: #2980b9;
}

.fen-panel {
  background-color: #f9f9f9;
  padding: 10px;
  border-radius: 5px;
  margin-top: 20px;
  text-align: center;
}

.fen-value {
  background-color: #eee;
  padding: 10px;
  border-radius: 5px;
  font-family: monospace;
  overflow-wrap: break-word;
  word-break: break-all;
}

.player-info {
  font-size: 16px;
  padding: 10px;
  text-align: center;
}

.white-color {
  color: #2c3e50;
  font-weight: bold;
}

.black-color {
  color: #e74c3c;
  font-weight: bold;
}
</style>
