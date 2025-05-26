import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/data/service/chess_websocket_service.dart';
import 'package:chess316/feature/chessboard/domain/FEN/fen_utils.dart';
import 'package:chess316/feature/chessboard/domain/board_resetter.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';
import 'package:flutter/cupertino.dart';

class ChessBoardViewModel extends ChangeNotifier {
  // Board state
  List<List<ChessPiece?>> _chessBoard = [];
  List<bool> _selectedPieces = [];
  List<bool> _validMoves = [];
  int _selectedFieldRow = -1;
  int _selectedFieldColumn = -1;
  int _selectedFieldIndex = -1;
  bool _isWhiteTurn = true;
  List<int> _whiteKingPosition = [7, 4];
  List<int> _blackKingPosition = [0, 4];
  bool _check = false;
  bool _checkMate = false;
  bool _isFieldEnabled = true;

  // Robot service
  final ChessRobotService _service = ChessRobotService();
  int _killedPiecesCount = 1;

  // Messages
  String _alertMessage = '';
  String _connectionErrorMessage = '';

  // WebSocket related properties
  final ChessWebSocketService _webSocketService = ChessWebSocketService();
  String _webSocketStatus = '';
  bool _webSocketError = false;
  bool _isWebSocketConnected = false;
  String? _playerColor; // 'w' or 'b'

  // Getters
  int get selectedFieldIndex => _selectedFieldIndex;
  int get selectedFieldRow => _selectedFieldRow;
  int get selectedFieldColumn => _selectedFieldColumn;
  List<bool> get selectedPieces => _selectedPieces;
  List<List<ChessPiece?>> get chessBoard => _chessBoard;
  List<bool> get validMoves => _validMoves;
  bool get check => _check;
  bool get checkMate => _checkMate;
  bool get isWhiteTurn => _isWhiteTurn;
  bool get isFieldEnabled => _isFieldEnabled;
  String get alertMessage => _alertMessage;
  String get connectionErrorMessage => _connectionErrorMessage;

  // WebSocket getters
  String get webSocketStatus => _webSocketStatus;
  bool get webSocketError => _webSocketError;
  bool get isWebSocketConnected => _isWebSocketConnected;

  ChessBoardViewModel() {
    initChessBoard();
    _setupWebSocketListeners();
  }

  /// Initialization of the chessboard, default placement of pieces
  void initChessBoard() {
    List<List<ChessPiece?>> initBoard = List.generate(
      8,
      (index) => List.generate(
        8,
        (index) => null,
      ),
    );
    List<bool> initSelectedPieces = List.generate(
      64,
      (index) => false,
    );

    List<bool> initValidMoves = List.generate(
      64,
      (index) => false,
    );

    for (int i = 0; i < 8; i++) {
      initBoard[1][i] = Pawn(isWhite: false);
      initBoard[6][i] = Pawn();
    }

    initBoard[0][0] = Rook(isWhite: false);
    initBoard[0][7] = Rook(isWhite: false);
    initBoard[7][0] = Rook();
    initBoard[7][7] = Rook();

    initBoard[0][1] = Knight(isWhite: false);
    initBoard[0][6] = Knight(isWhite: false);
    initBoard[7][1] = Knight();
    initBoard[7][6] = Knight();

    initBoard[0][2] = Bishop(isWhite: false);
    initBoard[0][5] = Bishop(isWhite: false);
    initBoard[7][2] = Bishop();
    initBoard[7][5] = Bishop();

    initBoard[0][3] = Queen(isWhite: false);
    initBoard[0][4] = King(isWhite: false);
    initBoard[7][3] = Queen();
    initBoard[7][4] = King();

    _chessBoard = initBoard;
    _selectedPieces = initSelectedPieces;
    _validMoves = initValidMoves;

    _selectedFieldRow = -1;
    _selectedFieldColumn = -1;
    _selectedFieldIndex = -1;
    _isWhiteTurn = true;
    _killedPiecesCount = 1;
    _whiteKingPosition = [7, 4];
    _blackKingPosition = [0, 4];
    _check = false;
    _checkMate = false;
    _alertMessage = '';
    notifyListeners();
  }

  /// Set a selected piece
  /// If user taps on already selected piece - it unselects
  /// If user selects piece it calls [simulateFutureMove] to calculate valid moves for a given piece
  /// If user taps on valid field after selecting the piece it calls the [movePiece] method
  void selectPiece(int index) {
    final row = index ~/ 8;
    final column = index % 8;

    // If WebSocket is connected, use WebSocket logic for moves
    if (_isWebSocketConnected) {
      if (_selectedPieces[index]) {
        setSelectedToDefault();
        clear();
      } else {
        if (_validMoves[index] == true && _selectedFieldIndex != -1) {
          // Get algebraic notation positions
          final selectedRow = _selectedFieldIndex ~/ 8;
          final selectedCol = _selectedFieldIndex % 8;
          final fromPos =
              FenUtils.positionToAlgebraic(selectedRow, selectedCol);
          final toPos = FenUtils.positionToAlgebraic(row, column);

          // Send move through WebSocket
          _webSocketService.makeMove(fromPos, toPos);
          _webSocketStatus = 'Sending move request...';
          _isFieldEnabled = false;

          // Clear selections
          setSelectedToDefault();
          clear();
          notifyListeners();
          return;
        } else {
          // Check if player can select this piece (color matches turn)
          bool canSelect = _chessBoard[row][column] != null;
          if (_playerColor != null) {
            canSelect = canSelect &&
                ((_playerColor == 'w' && _chessBoard[row][column]!.isWhite) ||
                    (_playerColor == 'b' &&
                        !_chessBoard[row][column]!.isWhite));
          } else {
            canSelect =
                canSelect && _chessBoard[row][column]!.isWhite == _isWhiteTurn;
          }

          if (canSelect) {
            clear();
            _selectedFieldIndex = index;
            _selectedFieldRow = row;
            _selectedFieldColumn = column;
            _selectedPieces[index] = true;

            final List<List<int>> moves = simulateFutureMove(
                _selectedFieldRow, _selectedFieldColumn, true);

            for (var move in moves) {
              _validMoves[move[0] * 8 + move[1]] = true;
            }
          }
        }
      }
      notifyListeners();
      return;
    }

    // Local game logic (original implementation)
    if (_selectedPieces[index]) {
      setSelectedToDefault();
      clear();
    } else {
      if (_validMoves[index] == true &&
          _chessBoard[_selectedFieldRow][_selectedFieldColumn] != null &&
          _chessBoard[_selectedFieldRow][_selectedFieldColumn]!.isWhite ==
              _isWhiteTurn) {
        movePiece(row, column);
      } else {
        if (_chessBoard[row][column] != null &&
            _chessBoard[row][column]!.isWhite == _isWhiteTurn) {
          clear();
          _selectedFieldIndex = index;
          _selectedFieldRow = row;
          _selectedFieldColumn = column;
          _selectedPieces[index] = true;

          final List<List<int>> moves =
              simulateFutureMove(_selectedFieldRow, _selectedFieldColumn, true);

          for (var move in moves) {
            _validMoves[move[0] * 8 + move[1]] = true;
          }
        }
      }
    }
    notifyListeners();
  }

  /// Moves the piece to a given [row] and [column] on the screen
  /// Calls [movePieceWithRobot] method to move a piece on a real chess board with Robot
  void movePiece(int row, int column) async {
    if (_chessBoard[_selectedFieldRow][_selectedFieldColumn]!.type ==
        ChessPieceType.king) {
      if (_chessBoard[_selectedFieldRow][_selectedFieldColumn]!.isWhite) {
        _whiteKingPosition = [row, column];
      } else {
        _blackKingPosition = [row, column];
      }
    }

    final robotRow = row;
    final robotColumn = column;
    final robotSelectedFieldRow = _selectedFieldRow;
    final robotSelectedFieldColumn = _selectedFieldColumn;
    final robotPiece = _chessBoard[row][column];

    _chessBoard[row][column] =
        _chessBoard[_selectedFieldRow][_selectedFieldColumn];

    _chessBoard[_selectedFieldRow][_selectedFieldColumn] = null;
    _isFieldEnabled = false;
    notifyListeners();

    if (isCheck(!_isWhiteTurn)) {
      _check = true;
      _alertMessage = 'Check';
    } else {
      _check = false;
      _alertMessage = '';
    }

    if (isCheckMate(!_isWhiteTurn)) {
      _alertMessage = 'Check Mate';
      _checkMate = true;
    }

    await movePieceWithRobot(robotRow, robotColumn, robotSelectedFieldRow,
        robotSelectedFieldColumn, robotPiece);

    _isWhiteTurn = !_isWhiteTurn;
    _isFieldEnabled = true;
    clear();
    notifyListeners();
  }

  /// Checks for check condition
  /// Returns true if there is a check, otherwise returns false
  bool isCheck(bool isWhiteKing) {
    List<int> kingPosition =
        isWhiteKing ? _whiteKingPosition : _blackKingPosition;

    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (_chessBoard[i][j] == null ||
            _chessBoard[i][j]!.isWhite == isWhiteKing) {
          continue;
        }
        List<List<int>> moves = simulateFutureMove(i, j, false);
        for (var move in moves) {
          if (move[0] == kingPosition[0] && move[1] == kingPosition[1]) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Checks for a checkmate condition.
  /// Returns true if there is a checkmate, otherwise returns false
  bool isCheckMate(bool isWhiteKing) {
    if (!isCheck(isWhiteKing)) {
      return false;
    }
    for (int i = 0; i < 8; i++) {
      for (int j = 0; j < 8; j++) {
        if (_chessBoard[i][j] == null ||
            _chessBoard[i][j]!.isWhite != isWhiteKing) {
          continue;
        }
        List<List<int>> validMoves = simulateFutureMove(i, j, true);
        if (validMoves.isNotEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  /// Simulates possible moves for a given piece at a specified position
  /// Returns a list of valid (safe) moves [realValidMoves] that the piece can make
  /// Is used for subsequent use in the logic of moving a piece or checking checkmate conditions.
  List<List<int>> simulateFutureMove(int row, int col, bool checkSimulation) {
    List<List<int>> realValidMoves = [];
    final ChessPiece? piece = _chessBoard[row][col];

    if (piece != null) {
      final List<List<int>> moves = piece.validMoves(row, col, _chessBoard);

      if (checkSimulation) {
        for (var move in moves) {
          int endRow = move[0];
          int endCol = move[1];
          if (futureMoveIsSafe(row, col, endRow, endCol, piece)) {
            realValidMoves.add(move);
          }
        }
      } else {
        realValidMoves = moves;
      }
    }

    return realValidMoves;
  }

  /// Checks the simulated move to see if it will lead to a check or not
  /// Return true if the move is safe, otherwise returns false
  bool futureMoveIsSafe(
      int startRow, int startCol, int endRow, int endCol, ChessPiece piece) {
    ChessPiece? originalDestinationPiece = _chessBoard[endRow][endCol];

    List<int>? originalKingPos;

    if (piece.type == ChessPieceType.king) {
      originalKingPos = piece.isWhite ? _whiteKingPosition : _blackKingPosition;

      if (piece.isWhite) {
        _whiteKingPosition = [endRow, endCol];
      } else {
        _blackKingPosition = [endRow, endCol];
      }
    }

    _chessBoard[endRow][endCol] = piece;
    _chessBoard[startRow][startCol] = null;

    bool moveIsSafe = !isCheck(piece.isWhite);

    _chessBoard[startRow][startCol] = piece;
    _chessBoard[endRow][endCol] = originalDestinationPiece;

    if (piece.isWhite) {
      _whiteKingPosition = originalKingPos ?? _whiteKingPosition;
    } else {
      _blackKingPosition = originalKingPos ?? _blackKingPosition;
    }

    return moveIsSafe;
  }

  /// Move chess piece with Robot
  /// Moves killed piece to the second chess board. Then moves the killer
  /// Will throw an exception if there is no connection to Robot with TCP/IP
  Future<void> movePieceWithRobot(int row, int column, int selectedRow,
      int selectedColumn, ChessPiece? piece) async {
    try {
      _service.checkConnection();
      final int positionFrom = positionFromMatrix(selectedRow, selectedColumn);
      final int positionTo = positionFromMatrix(row, column);
      if (piece != null) {
        // Move killed piece from the board
        await _service.moveChessPiece(2, positionTo, 1, _killedPiecesCount);
        // Add this move into reSetter
        BoardReSetter.addMove(
            boardFrom: 2,
            boardTo: 1,
            positionTo: _killedPiecesCount,
            positionFrom: positionTo);
        // After killed piece removed - move the killer
        await _service.moveChessPiece(2, positionFrom, 2, positionTo);
        // Add this move into reSetter
        BoardReSetter.addMove(
            boardFrom: 2,
            boardTo: 2,
            positionTo: positionTo,
            positionFrom: positionFrom);
        // Increment _killedPieceCount to move next killed piece to an empty field on the second board
        _killedPiecesCount++;
      } else {
        await _service.moveChessPiece(2, positionFrom, 2, positionTo);
        // Add this move into reSetter
        BoardReSetter.addMove(
            boardFrom: 2,
            boardTo: 2,
            positionTo: positionTo,
            positionFrom: positionFrom);
      }
    } catch (e) {
      _connectionErrorMessage = e.toString();
    }
  }

  int positionFromMatrix(int row, int col) {
    return (col + 1) + 8 * (7 - row);
  }

  /// Clears the selected and valid move states.
  void clear() {
    for (int i = 0; i < 64; i++) {
      _selectedPieces[i] = false;
      _validMoves[i] = false;
    }
  }

  /// Resets the selected field state.
  /// '-1' means nothing is selected.
  /// Moves chess pieces back to its default position
  void placePiecesToDefault() {
    BoardReSetter.reset((event) async {
      await _service.moveChessPiece(
          event.boardFrom, event.positionFrom, event.boardTo, event.positionTo);
    });
  }

  void setSelectedToDefault() {
    _selectedFieldIndex = -1;
    _selectedFieldRow = -1;
    _selectedFieldColumn = -1;
  }

  /// Restarts the game by initializing the chessboard again.
  void restartGame() {
    clear();
    placePiecesToDefault();
    setSelectedToDefault();
    initChessBoard();
  }

  // WebSocket related methods

  /// Set up WebSocket message listeners
  void _setupWebSocketListeners() {
    _webSocketService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    }, onError: (error) {
      _webSocketStatus = 'Communication error: ${error.toString()}';
      _webSocketError = true;
      notifyListeners();
    });
  }

  /// Connect to a WebSocket server
  Future<void> connectToWebSocket(String url) async {
    try {
      _webSocketStatus = 'Connecting...';
      _webSocketError = false;
      notifyListeners();

      await _webSocketService.connect(url);

      _isWebSocketConnected = _webSocketService.isConnected;
      if (_isWebSocketConnected) {
        _webSocketStatus = 'Connected to server';
        // Request initial board state
        _webSocketService.getBoardState();
      } else {
        _webSocketStatus = 'Connection failed';
        _webSocketError = true;
      }

      notifyListeners();
    } catch (e) {
      _webSocketStatus = 'Connection error: ${e.toString()}';
      _webSocketError = true;
      notifyListeners();
    }
  }

  /// Disconnect from WebSocket server
  void disconnectWebSocket() {
    _webSocketService.disconnect();
    _isWebSocketConnected = false;
    _webSocketStatus = 'Disconnected';
    notifyListeners();
  }

  /// Handle incoming WebSocket messages
  void _handleWebSocketMessage(Map<String, dynamic> message) {
    final messageType = message['type'];

    switch (messageType) {
      case 'init_game':
        // Initialize game
        _playerColor = message['data']['color']; // 'w' or 'b'
        _isWhiteTurn = true; // White always starts
        _webSocketStatus =
            'Game started, you play as ${_playerColor == 'w' ? 'white' : 'black'}';

        // Request initial board state
        _webSocketService.getBoardState();
        break;

      case 'update_game_state':
        // Update board state
        if (message['data'].containsKey('board_state')) {
          final fen = message['data']['board_state']['fen'];
          _updateBoardFromFen(fen);

          // Update turn information
          _isWhiteTurn = FenUtils.getIsWhiteTurn(fen);

          // Update check and checkmate status
          _check = isCheck(!_isWhiteTurn);
          if (_check) {
            _alertMessage = 'Check';
            _checkMate = isCheckMate(!_isWhiteTurn);
            if (_checkMate) {
              _alertMessage = 'Check Mate';
            }
          } else {
            _alertMessage = '';
            _checkMate = false;
          }

          _webSocketStatus = 'Board updated';
          _isFieldEnabled = true;
        }

        // Clear selection state
        clear();
        setSelectedToDefault();
        notifyListeners();
        break;

      case 'move_result':
        // Move result
        if (message['data']['status'] == 'success') {
          _webSocketStatus = 'Move successful';
          // Request updated board state
          _webSocketService.getBoardState();
        } else {
          _webSocketStatus = 'Move failed: ${message['data']['message']}';
          _webSocketError = true;
          _isFieldEnabled = true;
        }
        notifyListeners();
        break;

      case 'error':
        // Error handling
        _webSocketStatus = 'Error: ${message['error']['message']}';
        _webSocketError = true;
        _isFieldEnabled = true;
        notifyListeners();
        break;
    }
  }

  /// Update the board state from a FEN string
  void _updateBoardFromFen(String fen) {
    _chessBoard = FenUtils.fenToBoard(fen);

    // Update king positions
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        final piece = _chessBoard[row][col];
        if (piece != null && piece.type == ChessPieceType.king) {
          if (piece.isWhite) {
            _whiteKingPosition = [row, col];
          } else {
            _blackKingPosition = [row, col];
          }
        }
      }
    }

    notifyListeners();
  }

  /// Request refresh of the board state from server
  void refreshBoardState() {
    if (_isWebSocketConnected) {
      _webSocketService.getBoardState();
      _webSocketStatus = 'Requesting board state...';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
