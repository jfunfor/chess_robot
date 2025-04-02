import 'package:chess316/feature/chessboard_v2/data/service/mock_chess_backend_service.dart';
import 'package:chess316/feature/chessboard_v2/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard_v2/domain/models/fen_parser.dart';
import 'package:flutter/material.dart';

class ChessBoardViewModel extends ChangeNotifier {
  // Board state
  List<List<ChessPiece?>> board =
      List.generate(8, (_) => List.generate(8, (_) => null));

  // Game state
  List<int>? selectedPosition; // [row, col] of selected piece
  List<List<int>> possibleMoves = [];
  bool isWhiteTurn = true;
  String? playerColor; // 'w' or 'b'
  bool isGameActive = false;
  bool isLoading = true;
  String? statusMessage;
  bool isInCheck = false;
  bool isCheckmate = false;
  bool isStalemate = false;

  // Move history
  List<Map<String, dynamic>> moveHistory = [];
  List<int>? lastMove; // [fromRow, fromCol, toRow, toCol]

  // Special move tracking
  bool canWhiteCastleKingside = true;
  bool canWhiteCastleQueenside = true;
  bool canBlackCastleKingside = true;
  bool canBlackCastleQueenside = true;
  List<int>? enPassantTarget;
  int halfMoveClock = 0;
  int fullMoveNumber = 1;
  List<int>? pendingPromotion;
  final Function(String)? onBackendLog;

  // Backend service
  late MockChessBackendService _backendService;

  ChessBoardViewModel({this.onBackendLog}) {
    _initGame();
  }

  void _initGame() {
    _backendService = MockChessBackendService(
      onMessageReceived: (message) {
        if (onBackendLog != null) {
          onBackendLog!("← RECEIVED: ${message['type']}");
        }
        _handleBackendMessage(message);
      },
    );

    _backendService.getBoardState();
  }

  // Handle messages received from the backend
  void _handleBackendMessage(Map<String, dynamic>? message) {
    // 添加空检查
    if (message == null) {
      print('Received null backend message');
      return;
    }

    // 添加调试日志
    print('Received backend message: $message');

    try {
      if (message.containsKey('type')) {
        final messageType = message['type'];

        switch (messageType) {
          case 'init_game':
            _handleInitGame(message['data']);
            break;
          case 'update_game_state':
            _handleGameStateUpdate(message['data']);
            break;
          default:
            print('Unknown message type: $messageType');
        }
      } else if (message.containsKey('error')) {
        _handleError(message['error']);
      }
    } catch (e) {
      print('Error processing backend message: $e');
      // 使用默认初始化
      _handleInitGame(null);
    }

    isLoading = false;
    notifyListeners();
  }

  // Handle game initialization message
  void _handleInitGame(Map<String, dynamic>? data) {
    // 如果data为null，使用默认初始棋盘FEN
    if (data == null) {
      data = {
        'color': 'w',
        'board_state': {
          'fen': 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'
        }
      };
    }

    // 安全获取玩家颜色，默认为白色
    playerColor = (data['color'] ?? 'w') as String;
    isGameActive = true;
    statusMessage = 'Game initialized. White moves first.';

    // 安全获取FEN字符串，使用默认初始FEN
    String fen = data['board_state']?['fen'] ??
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

    // 使用标准初始位置
    _updateBoardFromFen(fen);

    // 重置游戏状态
    moveHistory = [];
    lastMove = null;
    isInCheck = false;
    isCheckmate = false;
    isStalemate = false;

    // 确保白棋先走
    isWhiteTurn = true;

    // 确保不在加载状态
    isLoading = false;

    notifyListeners();
  }

  // Handle game state update message
  void _handleGameStateUpdate(Map<String, dynamic> data) {
    // 解析并更新棋盘状态
    final fen = data['board_state']['fen'];
    _updateBoardFromFen(fen);

    // 更新当前轮次
    final currentTurn = data['player_color'] ?? 'w';
    isWhiteTurn = currentTurn == 'w';

    // 清除当前选择和可能的移动
    selectedPosition = null;
    possibleMoves = [];

    // 更新状态消息
    statusMessage = isWhiteTurn ? 'White\'s turn' : 'Black\'s turn';

    // 检查游戏状态
    _updateGameStatus();

    // 确保不在加载状态
    isLoading = false;

    notifyListeners();
  }

  // Update the board from FEN notation
  void _updateBoardFromFen(String fen) {
    Map<String, dynamic> parsedFen = FenParser.parseFen(fen);

    board = parsedFen['board'];
    isWhiteTurn = parsedFen['isWhiteTurn'];
    canWhiteCastleKingside = parsedFen['castlingRights'].contains('K');
    canWhiteCastleQueenside = parsedFen['castlingRights'].contains('Q');
    canBlackCastleKingside = parsedFen['castlingRights'].contains('k');
    canBlackCastleQueenside = parsedFen['castlingRights'].contains('q');

    if (parsedFen['enPassantTarget'] != '-') {
      enPassantTarget =
          FenParser.algebraicToCoords(parsedFen['enPassantTarget']);
    } else {
      enPassantTarget = null;
    }

    halfMoveClock = parsedFen['halfMoveClock'];
    fullMoveNumber = parsedFen['fullMoveNumber'];
  }

  // Convert current game state to FEN notation
  /*String _boardToFen() {
    String castlingRights = '';
    if (canWhiteCastleKingside) castlingRights += 'K';
    if (canWhiteCastleQueenside) castlingRights += 'Q';
    if (canBlackCastleKingside) castlingRights += 'k';
    if (canBlackCastleQueenside) castlingRights += 'q';
    if (castlingRights.isEmpty) castlingRights = '-';

    String enPassantSquare = enPassantTarget != null
        ? FenParser.coordsToAlgebraic(enPassantTarget![0], enPassantTarget![1])
        : '-';

    return FenParser.boardToFen(board, isWhiteTurn,
        castlingRights: castlingRights,
        enPassantTarget: enPassantSquare,
        halfMoveClock: halfMoveClock,
        fullMoveNumber: fullMoveNumber);
  }*/

  // Handle error message
  void _handleError(Map<String, dynamic> error) {
    statusMessage = 'Error: ${error['message']}';
  }

  // Select a piece
  void selectPiece(int row, int col) {
    // 允许任何颜色的棋子被选择
    if (!isGameActive) {
      return;
    }

    ChessPiece? piece = board[row][col];

    if (piece != null) {
      selectedPosition = [row, col];

      // 获取所有潜在有效走法
      List<List<int>> validMoves = _getValidMovesForPiece(row, col);

      // 过滤会导致将军的走法
      possibleMoves = validMoves.where((move) {
        return !_moveWouldLeaveInCheck(row, col, move[0], move[1]);
      }).toList();

      notifyListeners();
    }
  }

  // Move a piece
  void movePiece(int row, int col) {
    if (selectedPosition == null || !isGameActive) {
      return;
    }

    int fromRow = selectedPosition![0];
    int fromCol = selectedPosition![1];

    // 检查移动是否有效
    bool isValidMove =
        possibleMoves.any((move) => move[0] == row && move[1] == col);

    if (isValidMove) {
      // 检查是否需要升变
      ChessPiece? piece = board[fromRow][fromCol];
      if (piece is Pawn && (row == 0 || row == 7)) {
        pendingPromotion = [fromRow, fromCol, row, col];
        notifyListeners();
        return;
      }

      // 转换代数表示
      String startPos = FenParser.coordsToAlgebraic(fromRow, fromCol);
      String endPos = FenParser.coordsToAlgebraic(row, col);

      if (onBackendLog != null) {
        onBackendLog!("→ MOVE from $startPos to $endPos");
      }

      // 发送后端移动请求
      _backendService.makeMove(startPos, endPos);

      // 本地执行移动
      _executeMove(fromRow, fromCol, row, col);
    }
  }

  // Execute the move on the local board
  void _executeMove(int fromRow, int fromCol, int toRow, int toCol,
      {String? promotionPiece}) {
    ChessPiece? piece = board[fromRow][fromCol];
    if (piece == null) return;

    // Save the move for history
    Map<String, dynamic> moveData = {
      'piece': piece,
      'from': [fromRow, fromCol],
      'to': [toRow, toCol],
      'capturedPiece': board[toRow][toCol],
      'isCheck': false,
      'isCheckmate': false,
      'promotionPiece': promotionPiece,
    };

    // Save the last move for highlighting
    lastMove = [fromRow, fromCol, toRow, toCol];

    // Handle special moves

    // Castling
    if (piece is King && (fromCol - toCol).abs() > 1) {
      _handleCastling(fromRow, fromCol, toRow, toCol);
    }

    // En passant capture
    else if (piece is Pawn && fromCol != toCol && board[toRow][toCol] == null) {
      _handleEnPassant(fromRow, fromCol, toRow, toCol);
    }

    // Standard move or capture
    else {
      // Update castling rights if rook or king moves
      if (piece is King) {
        if (piece.isWhite) {
          canWhiteCastleKingside = false;
          canWhiteCastleQueenside = false;
        } else {
          canBlackCastleKingside = false;
          canBlackCastleQueenside = false;
        }
      } else if (piece is Rook) {
        if (piece.isWhite) {
          if (fromCol == 0 && fromRow == 7) canWhiteCastleQueenside = false;
          if (fromCol == 7 && fromRow == 7) canWhiteCastleKingside = false;
        } else {
          if (fromCol == 0 && fromRow == 0) canBlackCastleQueenside = false;
          if (fromCol == 7 && fromRow == 0) canBlackCastleKingside = false;
        }
      }

      // Move the piece
      board[toRow][toCol] = piece;
      board[fromRow][fromCol] = null;
    }

    // Handle pawn promotion
    if (piece is Pawn && (toRow == 0 || toRow == 7) && promotionPiece != null) {
      _handlePromotion(toRow, toCol, promotionPiece, piece.isWhite);
    }

    // Update en passant target
    if (piece is Pawn && (fromRow - toRow).abs() == 2) {
      enPassantTarget = [
        (fromRow + toRow) ~/ 2, // Middle row between start and end
        fromCol
      ];
    } else {
      enPassantTarget = null;
    }

    // Update half move clock (reset on pawn move or capture)
    if (piece is Pawn || board[toRow][toCol] != null) {
      halfMoveClock = 0;
    } else {
      halfMoveClock++;
    }

    // Update full move number after Black's move
    if (!isWhiteTurn) {
      fullMoveNumber++;
    }

    // Switch turns
    isWhiteTurn = !isWhiteTurn;

    // Check for check, checkmate, or stalemate
    _updateGameStatus();

    // Update move history
    moveData['isCheck'] = isInCheck;
    moveData['isCheckmate'] = isCheckmate;
    moveHistory.add(moveData);

    // Clear selection and possible moves
    selectedPosition = null;
    possibleMoves = [];

    notifyListeners();
  }

  // Handle castling move
  void _handleCastling(int fromRow, int fromCol, int toRow, int toCol) {
    // Move the king
    ChessPiece? king = board[fromRow][fromCol];
    board[toRow][toCol] = king;
    board[fromRow][fromCol] = null;

    // Determine rook positions and move the rook
    int rookFromCol, rookToCol;
    if (toCol > fromCol) {
      // Kingside castling
      rookFromCol = 7;
      rookToCol = toCol - 1;
    } else {
      // Queenside castling
      rookFromCol = 0;
      rookToCol = toCol + 1;
    }

    ChessPiece? rook = board[fromRow][rookFromCol];
    board[fromRow][rookToCol] = rook;
    board[fromRow][rookFromCol] = null;

    // Update castling rights
    if (king != null && king.isWhite) {
      canWhiteCastleKingside = false;
      canWhiteCastleQueenside = false;
    } else {
      canBlackCastleKingside = false;
      canBlackCastleQueenside = false;
    }
  }

  // Handle en passant capture
  void _handleEnPassant(int fromRow, int fromCol, int toRow, int toCol) {
    // Move the pawn
    ChessPiece? pawn = board[fromRow][fromCol];
    board[toRow][toCol] = pawn;
    board[fromRow][fromCol] = null;

    // Remove the captured pawn
    board[fromRow][toCol] = null;
  }

  // Handle pawn promotion
  void _handlePromotion(int row, int col, String pieceType, bool isWhite) {
    ChessPiece? newPiece;

    switch (pieceType) {
      case 'queen':
        newPiece = Queen(isWhite: isWhite);
        break;
      case 'rook':
        newPiece = Rook(isWhite: isWhite);
        break;
      case 'bishop':
        newPiece = Bishop(isWhite: isWhite);
        break;
      case 'knight':
        newPiece = Knight(isWhite: isWhite);
        break;
    }

    if (newPiece != null) {
      board[row][col] = newPiece;
    }
  }

  // Complete a pending pawn promotion
  void promotePawn(String pieceType) {
    if (pendingPromotion == null) return;

    int fromRow = pendingPromotion![0];
    int fromCol = pendingPromotion![1];
    int toRow = pendingPromotion![2];
    int toCol = pendingPromotion![3];

    // 执行移动并升变
    _executeMove(fromRow, fromCol, toRow, toCol, promotionPiece: pieceType);

    // 发送后端移动请求
    String startPos = FenParser.coordsToAlgebraic(fromRow, fromCol);
    String endPos = FenParser.coordsToAlgebraic(toRow, toCol);
    _backendService.makeMove(startPos, endPos);

    pendingPromotion = null;
  }

  // Get valid moves for a piece
  List<List<int>> _getValidMovesForPiece(int row, int col) {
    ChessPiece? piece = board[row][col];
    if (piece == null) return [];

    // Use the piece's built-in valid moves method
    return piece.validMoves(row, col, board);
  }

  // Check if a move would leave the king in check
  bool _moveWouldLeaveInCheck(int fromRow, int fromCol, int toRow, int toCol) {
    // Make a deep copy of the board
    List<List<ChessPiece?>> tempBoard =
        List.generate(8, (r) => List.generate(8, (c) => board[r][c]?.copy()));

    // Execute the move on the temporary board
    ChessPiece? piece = tempBoard[fromRow][fromCol];
    ChessPiece? captured = tempBoard[toRow][toCol];

    if (piece != null) {
      tempBoard[toRow][toCol] = piece;
      tempBoard[fromRow][fromCol] = null;

      // Handle en passant capture
      if (piece is Pawn && fromCol != toCol && captured == null) {
        tempBoard[fromRow][toCol] = null; // Remove the captured pawn
      }

      // Handle castling (move the rook too)
      if (piece is King && (fromCol - toCol).abs() > 1) {
        int rookFromCol = toCol > fromCol ? 7 : 0;
        int rookToCol = toCol > fromCol ? toCol - 1 : toCol + 1;

        ChessPiece? rook = tempBoard[fromRow][rookFromCol];
        if (rook != null) {
          tempBoard[fromRow][rookToCol] = rook;
          tempBoard[fromRow][rookFromCol] = null;
        }
      }

      // Find the king
      int kingRow = -1, kingCol = -1;
      for (int r = 0; r < 8; r++) {
        for (int c = 0; c < 8; c++) {
          if (tempBoard[r][c] is King &&
              tempBoard[r][c]!.isWhite == piece.isWhite) {
            kingRow = r;
            kingCol = c;
            break;
          }
        }
        if (kingRow != -1) break;
      }

      // Check if the king is in check after the move
      if (kingRow != -1) {
        return _isSquareAttackedOnBoard(
            tempBoard, kingRow, kingCol, !piece.isWhite);
      }
    }

    return false;
  }

  // Check if a square is attacked on a given board state
  bool _isSquareAttackedOnBoard(
      List<List<ChessPiece?>> board, int row, int col, bool byWhite) {
    // Check for pawn attacks
    int pawnDir = byWhite ? 1 : -1;
    for (int colOffset in [-1, 1]) {
      int r = row + pawnDir;
      int c = col + colOffset;
      if (_isInBounds(r, c) &&
          board[r][c] is Pawn &&
          board[r][c]!.isWhite == byWhite) {
        return true;
      }
    }

    // Check for knight attacks
    final knightOffsets = [
      [-2, -1],
      [-2, 1],
      [-1, -2],
      [-1, 2],
      [1, -2],
      [1, 2],
      [2, -1],
      [2, 1]
    ];

    for (var offset in knightOffsets) {
      int r = row + offset[0];
      int c = col + offset[1];
      if (_isInBounds(r, c) &&
          board[r][c] is Knight &&
          board[r][c]!.isWhite == byWhite) {
        return true;
      }
    }

    // Check for king attacks
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        int r = row + dr;
        int c = col + dc;
        if (_isInBounds(r, c) &&
            board[r][c] is King &&
            board[r][c]!.isWhite == byWhite) {
          return true;
        }
      }
    }

    // Check for rook/queen attacks
    final rookDirs = [
      [-1, 0],
      [0, 1],
      [1, 0],
      [0, -1]
    ];
    for (var dir in rookDirs) {
      int r = row + dir[0];
      int c = col + dir[1];
      while (_isInBounds(r, c)) {
        if (board[r][c] != null) {
          if (board[r][c]!.isWhite == byWhite &&
              (board[r][c] is Rook || board[r][c] is Queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    // Check for bishop/queen attacks
    final bishopDirs = [
      [-1, -1],
      [-1, 1],
      [1, -1],
      [1, 1]
    ];
    for (var dir in bishopDirs) {
      int r = row + dir[0];
      int c = col + dir[1];
      while (_isInBounds(r, c)) {
        if (board[r][c] != null) {
          if (board[r][c]!.isWhite == byWhite &&
              (board[r][c] is Bishop || board[r][c] is Queen)) {
            return true;
          }
          break;
        }
        r += dir[0];
        c += dir[1];
      }
    }

    return false;
  }

  // Check if coordinates are within the board
  bool _isInBounds(int row, int col) {
    return row >= 0 && row < 8 && col >= 0 && col < 8;
  }

  bool _isSquareAttacked(int row, int col, bool byWhite) {
    return _isSquareAttackedOnBoard(board, row, col, byWhite);
  }

  // Update game status (check, checkmate, stalemate)
  void _updateGameStatus() {
    // Find the current player's king
    int kingRow = -1, kingCol = -1;
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        if (board[r][c] is King && board[r][c]!.isWhite == isWhiteTurn) {
          kingRow = r;
          kingCol = c;
          break;
        }
      }
      if (kingRow != -1) break;
    }

    if (kingRow == -1) return; // King not found (shouldn't happen)

    // Check if the king is in check
    isInCheck = _isSquareAttacked(kingRow, kingCol, !isWhiteTurn);

    // Check if there are any legal moves
    bool hasLegalMoves = false;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece.isWhite == isWhiteTurn) {
          List<List<int>> moves = _getValidMovesForPiece(r, c);

          for (var move in moves) {
            if (!_moveWouldLeaveInCheck(r, c, move[0], move[1])) {
              hasLegalMoves = true;
              break;
            }
          }

          if (hasLegalMoves) break;
        }
      }
      if (hasLegalMoves) break;
    }

    if (!hasLegalMoves) {
      if (isInCheck) {
        isCheckmate = true;
        statusMessage =
            isWhiteTurn ? 'Checkmate! Black wins.' : 'Checkmate! White wins.';
      } else {
        isStalemate = true;
        statusMessage = 'Stalemate! The game is a draw.';
      }
      isGameActive = false;
    } else if (isInCheck) {
      statusMessage = isWhiteTurn ? 'White is in check!' : 'Black is in check!';
    }
  }

  // Request current board state
  void requestBoardState() {
    if (isGameActive) {
      isLoading = true;
      statusMessage = 'Getting board state...';
      notifyListeners();
      if (onBackendLog != null) {
        onBackendLog!("→ GET BOARD STATE");
      }

      _backendService.getBoardState();
    }
  }

  // Reset the game
  void resetGame() {
    _initializeBoard();

    // Log reset action if backend logging is enabled
    if (onBackendLog != null) {
      onBackendLog!("→ RESET GAME");
    }
  }

  // Fully initialize the board with all pieces in their standard starting positions
  void _initializeBoard() {
    // 重置棋盘到初始位置
    board = List.generate(8, (_) => List.generate(8, (_) => null));

    // 重新放置白棋
    board[7][0] = Rook(isWhite: true);
    board[7][1] = Knight(isWhite: true);
    board[7][2] = Bishop(isWhite: true);
    board[7][3] = Queen(isWhite: true);
    board[7][4] = King(isWhite: true);
    board[7][5] = Bishop(isWhite: true);
    board[7][6] = Knight(isWhite: true);
    board[7][7] = Rook(isWhite: true);
    for (int i = 0; i < 8; i++) {
      board[6][i] = Pawn(isWhite: true);
    }

    // 重新放置黑棋
    board[0][0] = Rook(isWhite: false);
    board[0][1] = Knight(isWhite: false);
    board[0][2] = Bishop(isWhite: false);
    board[0][3] = Queen(isWhite: false);
    board[0][4] = King(isWhite: false);
    board[0][5] = Bishop(isWhite: false);
    board[0][6] = Knight(isWhite: false);
    board[0][7] = Rook(isWhite: false);
    for (int i = 0; i < 8; i++) {
      board[1][i] = Pawn(isWhite: false);
    }

    // 重置游戏状态
    isWhiteTurn = true;
    selectedPosition = null;
    possibleMoves = [];
    lastMove = null;
    moveHistory = [];
    isInCheck = false;
    isCheckmate = false;
    isStalemate = false;
    halfMoveClock = 0;
    fullMoveNumber = 1;
    pendingPromotion = null;

    // 重置特殊移动权限
    canWhiteCastleKingside = true;
    canWhiteCastleQueenside = true;
    canBlackCastleKingside = true;
    canBlackCastleQueenside = true;
    enPassantTarget = null;

    // 设置状态消息
    statusMessage = 'Game restarted. White\'s turn';
    isGameActive = true;

    // 确保不在加载状态
    isLoading = false;

    notifyListeners();
  }
}
