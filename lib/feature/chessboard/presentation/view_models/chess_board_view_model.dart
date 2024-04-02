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

  String _alertMessage = '';

  int get selectedFieldIndex => _selectedFieldIndex;

  int get selectedFieldRow => _selectedFieldRow;

  int get selectedFieldColumn => _selectedFieldColumn;

  List<bool> get selectedPieces => _selectedPieces;

  List<List<ChessPiece?>> get chessBoard => _chessBoard;

  List<bool> get validMoves => _validMoves;

  bool get check => _check;

  bool get checkMate => _checkMate;

  bool get isWhiteTurn => _isWhiteTurn;

  String get alertMessage => _alertMessage;

  ChessBoardViewModel() {
    initChessBoard();
  }

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

  void movePiece(int row, int column) {
    if (_chessBoard[_selectedFieldRow][_selectedFieldColumn]!.type ==
        ChessPieceType.king) {
      if (_chessBoard[_selectedFieldRow][_selectedFieldColumn]!.isWhite) {
        _whiteKingPosition = [row, column];
      } else {
        _blackKingPosition = [row, column];
      }
    }

    _chessBoard[row][column] =
        _chessBoard[_selectedFieldRow][_selectedFieldColumn];

    _chessBoard[_selectedFieldRow][_selectedFieldColumn] = null;

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

    clear();
    notifyListeners();
  }

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

  void clear() {
    for (int i = 0; i < 64; i++) {
      _selectedPieces[i] = false;
      _validMoves[i] = false;
    }
  }

  void reset() {
    _selectedFieldIndex = -1;
    _selectedFieldRow = -1;
    _selectedFieldColumn = -1;
  }

  void restartGame() {
    clear();
    reset();
    initChessBoard();
  }
}
