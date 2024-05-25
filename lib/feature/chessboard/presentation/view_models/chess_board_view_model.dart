import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard/domain/board_resetter.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_pieces.dart';
import 'package:flutter/cupertino.dart';

class ChessBoardViewModel extends ChangeNotifier {
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

  final ChessRobotService _service = ChessRobotService();
  int _killedPiecesCount = 1;

  String _alertMessage = '';

  String _connectionErrorMessage = '';

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

  ChessBoardViewModel() {
    initChessBoard();
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
    _whiteKingPosition = [7, 4];
    _blackKingPosition = [0, 4];
    _check = false;
    _checkMate = false;
    _alertMessage = '';
    notifyListeners();
  }

  ///Set a selected piece
  ///If user taps on already selected piece - it unselects
  ///If user selects piece it calls [simulateFutureMove] to calculate valid moves for a given piece
  ///If user taps on valid field after selecting the piece it calls the [movePiece] method
  void selectPiece(int index) {
    final row = index ~/ 8;
    final column = index % 8;
    if (_selectedPieces[index]) {
      reset();
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

  ///Moves the piece to a given [row] and [column] on the screen
  ///Calls [movePieceWithRobot] method to move a piece on a real chess board with Robot
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
    final robotColumn = _selectedFieldRow;
    final robotSelectedFieldRow = _selectedFieldRow;
    final robotSelectedFieldColumn = _selectedFieldColumn;

    _chessBoard[row][column] =
        _chessBoard[_selectedFieldRow][_selectedFieldColumn];

    _chessBoard[_selectedFieldRow][_selectedFieldColumn] = null;
    _isFieldEnabled = false;
    notifyListeners();

    await movePieceWithRobot(
        robotRow, robotColumn, robotSelectedFieldRow, robotSelectedFieldColumn);
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

    _isWhiteTurn = !_isWhiteTurn;
    _isFieldEnabled = true;
    clear();
    notifyListeners();
  }

  ///Checks for check condition
  ///Returns true if there is a check, otherwise returns false
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

  ///Simulates possible moves for a given piece at a specified position
  ///Returns a list of valid (safe) moves [realValidMoves] that the piece can make
  ///Is used for subsequent use in the logic of moving a piece or checking checkmate conditions.
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

  ///Checks the simulated move to see if it will lead to a check or not
  ///Return true if the move is safe, otherwise returns false
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

  ///Move chess piece with Robot
  ///Firstly, moves killed piece to the second chess board. Then moves the killer
  ///Will throw an exception if there is no connection to Robot with TCP/IP
  Future<void> movePieceWithRobot(
      int row, int column, int selectedRow, int selectedColumn) async {
    try {
      _service.checkConnection();
      final int positionFrom = positionFromMatrix(selectedRow, selectedColumn);
      final int positionTo = positionFromMatrix(row, column);
      if (_chessBoard[row][column] != null) {
        //move killed piece from the board
        await _service.moveChessPiece(2, positionTo, 1, _killedPiecesCount);
        // add this move into reSetter
        BoardReSetter.addMove(
            boardFrom: 2,
            boardTo: 1,
            positionTo: _killedPiecesCount,
            positionFrom: positionTo);
        //after killed piece removed - move the killer
        await _service.moveChessPiece(2, positionFrom, 2, positionTo);
        // add this move into reSetter
        BoardReSetter.addMove(
            boardFrom: 2,
            boardTo: 2,
            positionTo: positionTo,
            positionFrom: positionFrom);
        //increment _killedPieceCount to move next killed piece to an empty field on the second board
        _killedPiecesCount++;
      } else {
        ///if none of pieces are killed, moves only one piece
        await _service.moveChessPiece(2, positionFrom, 2, positionTo);
        ///add this move into reSetter
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
  /// Moves pieces back to its initial position with chess robot
  void reset() {
    BoardReSetter.reset((event) async {
      await _service.moveChessPiece(
          event.boardFrom, event.positionFrom, event.boardTo, event.positionTo);
    });
    _selectedFieldIndex = -1;
    _selectedFieldRow = -1;
    _selectedFieldColumn = -1;
    _killedPiecesCount = 1;
  }

  /// Restarts the game by initializing the chessboard again.
  void restartGame() {
    clear();
    reset();
    initChessBoard();
  }
}
