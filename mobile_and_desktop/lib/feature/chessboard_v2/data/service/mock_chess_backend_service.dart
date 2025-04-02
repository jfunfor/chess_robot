import 'package:chess316/feature/chessboard_v2/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard_v2/domain/models/fen_parser.dart';

class MockChessBackendService {
  // Board state
  String _currentFen =
      'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
  bool _isWhiteTurn = true;
  final String _playerColor = 'w'; // Default player color is white

  // Internal board representation
  List<List<ChessPiece?>> _board = [];

  // Castling rights
  bool _canWhiteCastleKingside = true;
  bool _canWhiteCastleQueenside = true;
  bool _canBlackCastleKingside = true;
  bool _canBlackCastleQueenside = true;

  // En passant target square in algebraic notation (e.g., 'e3')
  String? _enPassantTarget;

  // Half-move clock for 50-move rule
  int _halfMoveClock = 0;

  // Full move number
  int _fullMoveNumber = 1;

  // Message handler callback
  final Function(Map<String, dynamic>) onMessageReceived;

  // Move history
  final List<String> _moveHistory = [];

  MockChessBackendService({required this.onMessageReceived}) {
    // Initialize the game
    _initializeGame();
  }

  void _initializeGame() {
    try {
      // 使用默认FEN，以防当前FEN无效
      String currentFen = _currentFen.isNotEmpty
          ? _currentFen
          : 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

      // 解析初始FEN并填充棋盘
      _board = FenParser.fenToBoard(currentFen);

      // 解析FEN的额外信息
      List<String> fenParts = currentFen.split(' ');

      // 默认值设置
      _isWhiteTurn = true;
      _canWhiteCastleKingside = true;
      _canWhiteCastleQueenside = true;
      _canBlackCastleKingside = true;
      _canBlackCastleQueenside = true;
      _enPassantTarget = null;
      _halfMoveClock = 0;
      _fullMoveNumber = 1;

      // 如果FEN格式完整，覆盖默认值
      if (fenParts.length >= 6) {
        // 轮次
        _isWhiteTurn = fenParts[1] == 'w';

        // 易位权限
        String castlingRights = fenParts[2];
        _canWhiteCastleKingside = castlingRights.contains('K');
        _canWhiteCastleQueenside = castlingRights.contains('Q');
        _canBlackCastleKingside = castlingRights.contains('k');
        _canBlackCastleQueenside = castlingRights.contains('q');

        // En passant目标
        _enPassantTarget = fenParts[3] != '-' ? fenParts[3] : null;

        // 半步和全步计数器
        try {
          _halfMoveClock = int.tryParse(fenParts[4]) ?? 0;
          _fullMoveNumber = int.tryParse(fenParts[5]) ?? 1;
        } catch (e) {
          print('Error parsing move counters: $e');
          _halfMoveClock = 0;
          _fullMoveNumber = 1;
        }
      }

      // 发送初始游戏消息
      _sendInitGameMessage();

      // 发送初始棋盘状态
      _sendGameStateUpdate();
    } catch (e) {
      print('Error initializing game: $e');

      // 完全失败时的兜底方案
      _board = FenParser.fenToBoard(
          'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
      _isWhiteTurn = true;
      _canWhiteCastleKingside = true;
      _canWhiteCastleQueenside = true;
      _canBlackCastleKingside = true;
      _canBlackCastleQueenside = true;
      _enPassantTarget = null;
      _halfMoveClock = 0;
      _fullMoveNumber = 1;

      _sendInitGameMessage();
      _sendGameStateUpdate();
    }
  }

  void _sendInitGameMessage() {
    onMessageReceived({
      'type': 'init_game',
      'data': {'color': _playerColor}
    });
  }

  void _sendGameStateUpdate() {
    onMessageReceived({
      'type': 'update_game_state',
      'data': {
        'board_state': {'fen': _currentFen},
        'player_color': _isWhiteTurn ? 'w' : 'b',
        'castling_rights': {
          'white_kingside': _canWhiteCastleKingside,
          'white_queenside': _canWhiteCastleQueenside,
          'black_kingside': _canBlackCastleKingside,
          'black_queenside': _canBlackCastleQueenside,
        },
        'en_passant_target': _enPassantTarget,
        'half_move_clock': _halfMoveClock,
        'full_move_number': _fullMoveNumber,
        'is_check': FenParser.isInCheck(_board, _isWhiteTurn),
      }
    });
  }

  void _sendErrorMessage(String errorMessage) {
    onMessageReceived({
      'error': {'message': errorMessage}
    });
  }

  // Process move request
  void makeMove(String startPos, String endPos, {String? promotion}) {
    print('Processing move request: $startPos -> $endPos');

    try {
      // 验证移动合法性的逻辑保持不变
      if (!FenParser.isValidMove(_board, startPos, endPos, _isWhiteTurn)) {
        _sendErrorMessage('Invalid move');
        return;
      }

      // 执行移动的逻辑保持不变
      List<int> startCoords = FenParser.algebraicToCoords(startPos);
      List<int> endCoords = FenParser.algebraicToCoords(endPos);
      int startRow = startCoords[0];
      int startCol = startCoords[1];
      int endRow = endCoords[0];
      int endCol = endCoords[1];

      ChessPiece? piece = _board[startRow][startCol];
      if (piece == null) {
        _sendErrorMessage('No piece at start position');
        return;
      }

      // 处理升变
      bool needsPromotion = false;
      if (piece is Pawn && (endRow == 0 || endRow == 7)) {
        if (promotion == null) {
          promotion = 'queen'; // 默认升变为后
        }
        needsPromotion = true;
      }

      // 执行移动
      Map<String, dynamic> result = FenParser.executeMove(
          _board, startPos, endPos, _isWhiteTurn,
          promotionPiece: promotion);
      _board = result['board'];
      _isWhiteTurn = result['isWhiteTurn'];

      // Update castling rights based on king and rook movements
      _updateCastlingRights(piece, startRow, startCol);

      // Update en passant target
      _updateEnPassantTarget(piece, startRow, endRow, startCol);

      // Update move clocks
      _updateMoveClock(piece, _board[endRow][endCol]);

      // Update FEN string
      _updateFenString();

      // Record move
      _recordMove(startPos, endPos, needsPromotion, promotion);

      // Check for game over conditions
      if (_isGameOver()) {
        _sendGameStateUpdate();
        return;
      }

      // Send updated game state
      _sendGameStateUpdate();
    } catch (e) {
      _sendErrorMessage('Move error: $e');
    }
  }

// Helper method to update castling rights
  void _updateCastlingRights(ChessPiece? piece, int startRow, int startCol) {
    if (piece is King) {
      if (piece.isWhite) {
        _canWhiteCastleKingside = false;
        _canWhiteCastleQueenside = false;
      } else {
        _canBlackCastleKingside = false;
        _canBlackCastleQueenside = false;
      }
    } else if (piece is Rook) {
      if (piece.isWhite) {
        if (startRow == 7 && startCol == 0) _canWhiteCastleQueenside = false;
        if (startRow == 7 && startCol == 7) _canWhiteCastleKingside = false;
      } else {
        if (startRow == 0 && startCol == 0) _canBlackCastleQueenside = false;
        if (startRow == 0 && startCol == 7) _canBlackCastleKingside = false;
      }
    }
  }

// Helper method to update en passant target
  void _updateEnPassantTarget(
      ChessPiece? piece, int startRow, int endRow, int startCol) {
    if (piece is Pawn && (startRow - endRow).abs() == 2) {
      int enPassantRow = (startRow + endRow) ~/ 2;
      _enPassantTarget = FenParser.coordsToAlgebraic(enPassantRow, startCol);
    } else {
      _enPassantTarget = '-';
    }
  }

// Helper method to update move clocks
  void _updateMoveClock(ChessPiece? piece, ChessPiece? capturedPiece) {
    // Reset half-move clock on pawn move or capture
    if (piece is Pawn || capturedPiece != null) {
      _halfMoveClock = 0;
    } else {
      _halfMoveClock++;
    }

    // Increment full move number after Black's move
    if (!_isWhiteTurn) {
      _fullMoveNumber++;
    }
  }

// Helper method to record move
  void _recordMove(
      String startPos, String endPos, bool needsPromotion, String? promotion) {
    String moveNotation = '$startPos-$endPos';
    if (needsPromotion && promotion != null) {
      moveNotation += '=$promotion';
    }
    _moveHistory.add(moveNotation);
  }

  // Update the FEN string from current board state
  void _updateFenString() {
    // 1. Board position
    String boardFen = '';
    for (int r = 0; r < 8; r++) {
      int emptyCount = 0;
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = _board[r][c];
        if (piece == null) {
          emptyCount++;
        } else {
          if (emptyCount > 0) {
            boardFen += emptyCount.toString();
            emptyCount = 0;
          }

          String pieceChar = '';
          if (piece is Pawn) {
            pieceChar = 'p';
          } else if (piece is Rook) {
            pieceChar = 'r';
          } else if (piece is Knight) {
            pieceChar = 'n';
          } else if (piece is Bishop) {
            pieceChar = 'b';
          } else if (piece is Queen) {
            pieceChar = 'q';
          } else if (piece is King) {
            pieceChar = 'k';
          }

          boardFen += piece.isWhite ? pieceChar.toUpperCase() : pieceChar;
        }
      }

      if (emptyCount > 0) {
        boardFen += emptyCount.toString();
      }

      if (r < 7) {
        boardFen += '/';
      }
    }

    // 2. Active color
    String activeColor = _isWhiteTurn ? 'w' : 'b';

    // 3. Castling rights
    String castlingRights = '';
    if (_canWhiteCastleKingside) castlingRights += 'K';
    if (_canWhiteCastleQueenside) castlingRights += 'Q';
    if (_canBlackCastleKingside) castlingRights += 'k';
    if (_canBlackCastleQueenside) castlingRights += 'q';
    if (castlingRights.isEmpty) castlingRights = '-';

    // 4. En passant target square
    String enPassant = _enPassantTarget ?? '-';

    // 5. Halfmove clock
    String halfMove = _halfMoveClock.toString();

    // 6. Fullmove number
    String fullMove = _fullMoveNumber.toString();

    // Combine all parts
    _currentFen =
        '$boardFen $activeColor $castlingRights $enPassant $halfMove $fullMove';
  }

  // Check if the game is over (checkmate or stalemate)
  bool _isGameOver() {
    // Check if current player has any legal moves
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = _board[r][c];
        if (piece != null && piece.isWhite == _isWhiteTurn) {
          List<List<int>> moves = piece.validMoves(r, c, _board);

          for (List<int> move in moves) {
            int endRow = move[0];
            int endCol = move[1];

            // Check if move would leave king in check
            if (!FenParser.moveWouldLeaveKingInCheck(
                _board, piece, r, c, endRow, endCol)) {
              return false; // Found a legal move, game not over
            }
          }
        }
      }
    }

    // No legal moves - check if king is in check
    bool kingInCheck = FenParser.isInCheck(_board, _isWhiteTurn);

    if (kingInCheck) {
      _sendErrorMessage('Checkmate! ${_isWhiteTurn ? "Black" : "White"} wins!');
    } else {
      _sendErrorMessage('Stalemate! Game is a draw.');
    }

    return true;
  }

  // Simulate opponent move
  /*void _simulateOpponentMove() {
    // Delay to simulate thinking
    Future.delayed(Duration(seconds: 1), () {
      // Find all possible moves for opponent
      List<Map<String, dynamic>> allMoves = [];

      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          ChessPiece? piece = _board[r][c];
          if (piece != null && piece.isWhite == _isWhiteTurn) {
            List<List<int>> moves = piece.validMoves(r, c, _board);

            for (List<int> move in moves) {
              int endRow = move[0];
              int endCol = move[1];

              // Check if move is legal
              if (!FenParser.moveWouldLeaveKingInCheck(
                  _board, piece, r, c, endRow, endCol)) {
                allMoves.add({
                  'startRow': r,
                  'startCol': c,
                  'endRow': endRow,
                  'endCol': endCol,
                  'isPawnPromotion':
                      piece is Pawn && (endRow == 0 || endRow == 7)
                });
              }
            }
          }
        }
      }

      if (allMoves.isEmpty) {
        // No legal moves - game over
        _isGameOver();
        return;
      }

      // Choose a random move
      final random = DateTime.now().millisecondsSinceEpoch % allMoves.length;
      final move = allMoves[random];

      // Convert to algebraic notation
      String startPos =
          FenParser.coordsToAlgebraic(move['startRow'], move['startCol']);
      String endPos =
          FenParser.coordsToAlgebraic(move['endRow'], move['endCol']);

      // Handle promotion
      String? promotion;
      if (move['isPawnPromotion'] == true) {
        // Always promote to queen for AI moves
        promotion = 'queen';
      }

      // Execute the move
      makeMove(startPos, endPos, promotion: promotion);
    });
  }*/

  // Get current board state
  void getBoardState() {
    // 模拟初始状态
    final initialState = {
      'type': 'init_game',
      'data': {
        'color': 'w', // 默认白棋
        'board_state': {
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
        },
        'player_color': 'w'
      }
    };
    onMessageReceived.call(initialState);
  }
}
