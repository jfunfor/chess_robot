<template>
  <div class="chess-container">
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
        <h3>Срубленные черные фигуры:</h3>
        <div v-for="(piece, index) in capturedPieces.b" :key="'b'+index" class="captured-piece">
          <img :src="`/img/chesspieces/wikipedia/${piece}.png`" :alt="piece" />
        </div>
      </div>

      <!-- Центральная часть: шахматная доска -->
      <div class="board-container">
        <div id="board" class="chess-board"></div>
        <div class="controls">
          <button @click="resetBoard" class="control-button">Сбросить доску</button>
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
        <h3>Срубленные белые фигуры:</h3>
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
      capturedPieces: {
        w: [], // Срубленные белые фигуры
        b: []  // Срубленные черные фигуры
      }
    };
  },
  computed: {
    currentTurnText() {
      return this.game.turn() === 'w' ? 'Ход белых' : 'Ход черных';
    }
  },
  mounted() {
    // Инициализация jQuery в глобальном контексте
    window.$ = $;
    window.jQuery = $;

    // Подключение к WebSocket
    this.socket = new WebSocket('ws://localhost:8000');

    this.socket.onopen = () => {
      console.log('Connected to WebSocket server');
    };

    this.socket.onmessage = (event) => {
      const data = JSON.parse(event.data);

      if (data.type === 'init_game') {
        this.playerColor = data.data.color;
        console.log(`You are playing as: ${this.playerColor === 'w' ? 'white' : 'black'}`);
        this.initBoard(); // Инициализируем доску с правильной ориентацией
      }
      else if (data.type === 'update_game_state') {
        if (data.data.board_state && data.data.board_state.fen) {
          // Обновление состояния доски
          this.currentFen = data.data.board_state.fen;
          this.game.load(this.currentFen);
          this.board.position(this.currentFen);

          // Обновление срубленных фигур
          this.updateCapturedPieces();
        }
      }
    };

    // Инициализация шахматной доски
 this.board = Chessboard('board', {
  position: 'start',
  draggable: true,
  pieceTheme: '/img/chesspieces/wikipedia/{piece}.png',
   orientation: this.playerColor === 'w' ? 'white' : 'black',
  onDragStart: this.handleDragStart,
  onDrop: this.handleDrop,
  onSnapEnd: this.onSnapEnd,
  // Подключаем обработчики событий для подсветки ходов
  onMouseoverSquare: this.handleMouseoverSquare,
  onMouseoutSquare: this.handleMouseoutSquare
    });

    // Устанавливаем начальное значение FEN
    this.currentFen = this.game.fen();

    // Устанавливаем размер доски
    this.$nextTick(() => {
      const boardElement = document.getElementById('board');
      if (boardElement) {
        boardElement.style.width = '1200px';
        boardElement.style.height = '1200px';
        this.board.resize();
      }
    });
  },
  methods: {
    initBoard() {
      // Инициализация шахматной доски с ориентацией игрока
      this.board = Chessboard('board', {
        position: 'start',
        draggable: true,
        pieceTheme: '/img/chesspieces/wikipedia/{piece}.png',
        orientation: this.playerColor === 'w' ? 'white' : 'black', // Устанавливаем ориентацию
        onDragStart: this.handleDragStart,
        onDrop: this.handleDrop,
        onSnapEnd: this.handleSnapEnd,
        // Подключаем обработчики событий для подсветки ходов
        onMouseoverSquare: this.handleMouseoverSquare,
        onMouseoutSquare: this.handleMouseoutSquare
      });
      this.currentFen = this.game.fen();
    },
    // Обработчик начала перетаскивания фигуры
    handleDragStart(source, piece) {
      // Проверяем, может ли игрок двигать эту фигуру
      // Запрещаем ходить чужими фигурами
      if ((this.playerColor === 'w' && piece.search(/^b/) !== -1) ||
          (this.playerColor === 'b' && piece.search(/^w/) !== -1)) {
        return false;
      }

      // Проверяем, чей сейчас ход
      if ((this.game.turn() === 'w' && this.playerColor === 'b') ||
          (this.game.turn() === 'b' && this.playerColor === 'w')) {
        return false;
      }

      return true;
    },

    // Обработчик завершения перетаскивания фигуры
    handleDrop(source, target) {
      // Проверка валидности хода локально
      const move = this.game.move({
        from: source,
        to: target,
        promotion: 'q' // Автоматическое превращение пешки в ферзя
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
    },

    // После завершения анимации перетаскивания
    onSnapEnd() {
      this.board.position(this.game.fen());
    },
    updateBoardState() {
      // Обновляем состояние доски на основе текущей FEN-строки
      this.board.position(this.currentFen);},

    // Сброс доски до начального состояния
    resetBoard() {
      this.socket.send(JSON.stringify({
        type: 'reset_board'
      }));
    },
    getPieceImage(piece) {
      // Формируем путь к изображению с заглавной буквой типа фигуры
      const color = piece.charAt(0); // Цвет фигуры ('w' или 'b')
      const type = piece.charAt(1).toUpperCase(); // Тип фигуры ('P', 'N', 'B', ...)
      return `/img/chesspieces/wikipedia/${color}${type}.png`;
    },
    handleMouseoverSquare(square) {
      // Получаем список возможных ходов для выбранной клетки
      const moves = this.game.moves({
        square: square,
        verbose: true
      });

      if (moves.length === 0) return;

      // Подсвечиваем выбранную клетку
      this.greySquare(square);

      // Подсвечиваем клетки, куда можно пойти
      for (const move of moves) {
        this.greySquare(move.to);
      }
    },
    handleMouseoutSquare() {
      // Убираем подсветку при выходе мыши с клетки
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
    // Обновление списка срубленных фигур
    updateCapturedPieces() {
      const pieces = this.game.board().flat().filter(Boolean);

      // Изначальное количество фигур каждого типа
      const initialSetup = {
        'w': { 'p': 8, 'r': 2, 'n': 2, 'b': 2, 'q': 1, 'k': 1 },
        'b': { 'p': 8, 'r': 2, 'n': 2, 'b': 2, 'q': 1, 'k': 1 }
      };

      // Подсчет текущих фигур
      const currentCount = {
        'w': { 'p': 0, 'r': 0, 'n': 0, 'b': 0, 'q': 0, 'k': 0 },
        'b': { 'p': 0, 'r': 0, 'n': 0, 'b': 0, 'q': 0, 'k': 0 }
      };

      pieces.forEach(p => {
        if (p && p.type && p.color) {
          currentCount[p.color][p.type]++;
        }
      });

      // Очищаем текущие массивы срубленных фигур
      this.capturedPieces = { w: [], b: [] };

      // Вычисляем срубленные фигуры
      Object.keys(initialSetup).forEach(color => {
        Object.keys(initialSetup[color]).forEach(piece => {
          const count = currentCount[color][piece];
          const diff = initialSetup[color][piece] - count;

          // Добавляем срубленные фигуры
          for (let i = 0; i < diff; i++) {
            // Если белая фигура срублена, добавляем ее в массив черных срубленных фигур и наоборот
            if (color === 'w') {
              this.capturedPieces.w.push(`w${piece}`);
            } else {
              this.capturedPieces.b.push(`b${piece}`);
            }
          }
        });
      });
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
.chess-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 20px;
  font-family: Arial, sans-serif;
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
  width: 40px;
  height: 40px;
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
}

.control-button {
  padding: 10px 20px;
  background-color: #3498db;
  color: white;
  border: none;
  border-radius: 5px;
  cursor: pointer;
  font-size: 16px;
}

.control-button:hover {
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
