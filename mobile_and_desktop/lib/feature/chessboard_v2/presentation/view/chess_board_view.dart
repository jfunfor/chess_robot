import 'package:chess316/feature/chessboard_v2/data/service/mock_chess_backend_service.dart';
import 'package:chess316/feature/chessboard_v2/domain/models/chess_pieces.dart';
import 'package:chess316/feature/chessboard_v2/domain/models/fen_parser.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessBoardView extends StatelessWidget {
  const ChessBoardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChessBoardViewModel(),
      child: Consumer<ChessBoardViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Chess Game v2'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => viewModel.requestBoardState(),
                  tooltip: 'Refresh Board',
                ),
              ],
            ),
            body: Column(
              children: [
                // Status bar
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Turn: ${viewModel.isWhiteTurn ? 'White' : 'Black'}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color:
                              viewModel.isWhiteTurn ? Colors.blue : Colors.red,
                        ),
                      ),
                      if (viewModel.statusMessage != null)
                        Text(
                          viewModel.statusMessage!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      if (viewModel.isInCheck)
                        Text(
                          'CHECK!',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                    ],
                  ),
                ),

                // Main content - Chess board
                Expanded(
                  child: Center(
                    child: viewModel.isLoading
                        ? const CircularProgressIndicator()
                        : _buildChessBoard(context, viewModel),
                  ),
                ),

                // Game controls
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => viewModel.resetGame(),
                        child: const Text('New Game'),
                      ),
                      ElevatedButton(
                        onPressed: () => _showMoveHistory(context, viewModel),
                        child: const Text('Move History'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChessBoard(BuildContext context, ChessBoardViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: Column(
            children: [
              // File labels (a-h)
              _buildFileLabels(),

              // Board squares with rank labels
              Expanded(
                child: Row(
                  children: [
                    // Rank labels (1-8)
                    _buildRankLabels(),

                    // Chess board squares
                    Expanded(
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                        ),
                        itemCount: 64,
                        itemBuilder: (context, index) {
                          final row = index ~/ 8;
                          final col = index % 8;
                          final isDarkSquare = (row + col) % 2 == 1;
                          final piece = viewModel.board[row][col];

                          // Check if this is a possible move location
                          bool isPossibleMove = false;
                          for (var move in viewModel.possibleMoves) {
                            if (move[0] == row && move[1] == col) {
                              isPossibleMove = true;
                              break;
                            }
                          }

                          // Check if this is the selected piece
                          bool isSelected =
                              viewModel.selectedPosition != null &&
                                  viewModel.selectedPosition![0] == row &&
                                  viewModel.selectedPosition![1] == col;

                          // Check if this is the last move
                          bool isLastMoveFrom = viewModel.lastMove != null &&
                              viewModel.lastMove![0] == row &&
                              viewModel.lastMove![1] == col;

                          bool isLastMoveTo = viewModel.lastMove != null &&
                              viewModel.lastMove![2] == row &&
                              viewModel.lastMove![3] == col;

                          return GestureDetector(
                            onTap: () {
                              if (isPossibleMove) {
                                viewModel.movePiece(row, col);
                              } else {
                                viewModel.selectPiece(row, col);
                              }
                            },
                            child: Container(
                              color: isSelected
                                  ? Colors.yellow.withOpacity(0.7)
                                  : (isPossibleMove
                                      ? Colors.green.withOpacity(0.5)
                                      : (isLastMoveFrom || isLastMoveTo
                                          ? Colors.lightBlue.withOpacity(0.5)
                                          : (isDarkSquare
                                              ? Colors.brown
                                              : Colors.white))),
                              child: piece != null
                                  ? Center(
                                      child: _buildChessPiece(piece),
                                    )
                                  : isPossibleMove
                                      ? Center(
                                          child: Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.green.withOpacity(0.7),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        )
                                      : null,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileLabels() {
    return Row(
      children: [
        // Space for rank labels
        SizedBox(width: 20),

        // File labels a-h
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h']
                .map((file) => Text(
                      file,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRankLabels() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        8,
        (index) => SizedBox(
          width: 20,
          child: Text(
            '${8 - index}',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildChessPiece(ChessPiece piece) {
    String symbol;

    if (piece is Pawn) {
      symbol = piece.isWhite ? '♙' : '♟';
    } else if (piece is Rook) {
      symbol = piece.isWhite ? '♖' : '♜';
    } else if (piece is Knight) {
      symbol = piece.isWhite ? '♘' : '♞';
    } else if (piece is Bishop) {
      symbol = piece.isWhite ? '♗' : '♝';
    } else if (piece is Queen) {
      symbol = piece.isWhite ? '♕' : '♛';
    } else if (piece is King) {
      symbol = piece.isWhite ? '♔' : '♚';
    } else {
      symbol = '?';
    }

    return Text(
      symbol,
      style: TextStyle(
        fontSize: 36,
        color: piece.isWhite ? Colors.white : Colors.black,
        shadows: [
          Shadow(
            color: piece.isWhite ? Colors.black : Colors.white,
            blurRadius: 2,
            offset: const Offset(1, 1),
          ),
        ],
      ),
    );
  }

  void _showMoveHistory(BuildContext context, ChessBoardViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move History'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: viewModel.moveHistory.length,
            itemBuilder: (context, index) {
              final move = viewModel.moveHistory[index];
              final moveNumber = (index ~/ 2) + 1;

              if (index % 2 == 0) {
                // White's move
                return Row(
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text('$moveNumber.'),
                    ),
                    Text(move),
                    if (index + 1 < viewModel.moveHistory.length)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(viewModel.moveHistory[index + 1]),
                      ),
                  ],
                );
              } else {
                // Black's move (already shown with white's move)
                return SizedBox.shrink();
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  /*void _showPromotionDialog(
      BuildContext context, ChessBoardViewModel viewModel, int row, int col) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Promote Pawn'),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _promotionOption(context, viewModel, row, col, 'queen'),
            _promotionOption(context, viewModel, row, col, 'rook'),
            _promotionOption(context, viewModel, row, col, 'bishop'),
            _promotionOption(context, viewModel, row, col, 'knight'),
          ],
        ),
      ),
    );
  }*/

  /*Widget _promotionOption(BuildContext context, ChessBoardViewModel viewModel,
      int row, int col, String pieceType) {
    String symbol;
    bool isWhite = viewModel.isWhiteTurn;

    switch (pieceType) {
      case 'queen':
        symbol = isWhite ? '♕' : '♛';
        break;
      case 'rook':
        symbol = isWhite ? '♖' : '♜';
        break;
      case 'bishop':
        symbol = isWhite ? '♗' : '♝';
        break;
      case 'knight':
        symbol = isWhite ? '♘' : '♞';
        break;
      default:
        symbol = '?';
    }

    return GestureDetector(
      onTap: () {
        viewModel.promotePawn(row, col, pieceType);
        Navigator.of(context).pop();
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: 36,
              color: isWhite ? Colors.white : Colors.black,
              shadows: [
                Shadow(
                  color: isWhite ? Colors.black : Colors.white,
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }*/
}

// Here's the updated ViewModel class that would support the UI

class ChessBoardViewModel extends ChangeNotifier {
  List<List<ChessPiece?>> board =
      List.generate(8, (_) => List.generate(8, (_) => null));
  bool isWhiteTurn = true;
  bool isLoading = true;
  bool isInCheck = false;
  String? statusMessage;
  List<List<int>> possibleMoves = [];
  List<int>? selectedPosition;
  List<int>? lastMove; // [fromRow, fromCol, toRow, toCol]
  List<String> moveHistory = [];

  // Use this service to handle chess logic including validation
  final MockChessBackendService _chessService;

  ChessBoardViewModel()
      : _chessService = MockChessBackendService(onMessageReceived: (message) {
          // Handle messages from the chess service
        }) {
    // Initialize the game
    _initializeGame();
  }

  void _initializeGame() {
    // Initialize the board with starting position
    _loadBoardFromFen(
        'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1');
    isLoading = false;
    notifyListeners();
  }

  void _loadBoardFromFen(String fen) {
    board = FenParser.fenToBoard(fen);
    isWhiteTurn = fen.split(' ')[1] == 'w';

    // Check if king is in check
    isInCheck = FenParser.isInCheck(board, isWhiteTurn);

    notifyListeners();
  }

  void requestBoardState() {
    isLoading = true;
    notifyListeners();

    _chessService.getBoardState();

    // For immediate UI feedback, we'll simulate the response
    Future.delayed(Duration(milliseconds: 300), () {
      isLoading = false;
      notifyListeners();
    });
  }

  void selectPiece(int row, int col) {
    // Clear previous selection
    possibleMoves = [];

    // Get the selected piece
    ChessPiece? piece = board[row][col];

    // Check if there's a piece and it's the current player's turn
    if (piece != null && piece.isWhite == isWhiteTurn) {
      selectedPosition = [row, col];

      // Get valid moves for this piece
      List<List<int>> validMoves = piece.validMoves(row, col, board);

      // Filter moves that would leave king in check
      for (var move in validMoves) {
        if (!FenParser.moveWouldLeaveKingInCheck(
            board, piece, row, col, move[0], move[1])) {
          possibleMoves.add(move);
        }
      }

      notifyListeners();
    } else {
      selectedPosition = null;
      notifyListeners();
    }
  }

  void movePiece(int toRow, int toCol) {
    if (selectedPosition == null) return;

    int fromRow = selectedPosition![0];
    int fromCol = selectedPosition![1];

    // Get algebraic notation of the move
    String startPos = FenParser.coordsToAlgebraic(fromRow, fromCol);
    String endPos = FenParser.coordsToAlgebraic(toRow, toCol);

    // Check for pawn promotion
    ChessPiece? piece = board[fromRow][fromCol];
    if (piece is Pawn && (toRow == 0 || toRow == 7)) {
      // Handle promotion in the UI
      _handlePawnPromotion(fromRow, fromCol, toRow, toCol);
      return;
    }

    // Execute the move
    _executeMove(startPos, endPos);
  }

  void _executeMove(String startPos, String endPos) {
    // Execute move through the chess service
    _chessService.makeMove(startPos, endPos);

    // For immediate UI feedback, we'll simulate the response
    List<int> startCoords = FenParser.algebraicToCoords(startPos);
    List<int> endCoords = FenParser.algebraicToCoords(endPos);

    ChessPiece? piece = board[startCoords[0]][startCoords[1]];

    if (piece != null) {
      // Update board locally
      Map<String, dynamic> result =
          FenParser.executeMove(board, startPos, endPos, isWhiteTurn);
      board = result['board'];
      isWhiteTurn = result['isWhiteTurn'];

      // Record the move
      lastMove = [startCoords[0], startCoords[1], endCoords[0], endCoords[1]];
      moveHistory.add('${startPos}-${endPos}');

      // Check for check
      isInCheck = FenParser.isInCheck(board, isWhiteTurn);

      // Check for checkmate or stalemate
      if (_isGameOver()) {
        // Game has ended
      }

      // Clear selection and possible moves
      selectedPosition = null;
      possibleMoves = [];

      notifyListeners();
    }
  }

  void _handlePawnPromotion(int fromRow, int fromCol, int toRow, int toCol) {
    // Default to Queen promotion
    ChessPiece? pawn = board[fromRow][fromCol];
    if (pawn != null) {
      board[toRow][toCol] = Queen(isWhite: pawn.isWhite);
      board[fromRow][fromCol] = null;

      // Toggle turn
      isWhiteTurn = !isWhiteTurn;

      // Record the move
      String startPos = FenParser.coordsToAlgebraic(fromRow, fromCol);
      String endPos = FenParser.coordsToAlgebraic(toRow, toCol);
      lastMove = [fromRow, fromCol, toRow, toCol];
      moveHistory.add('${startPos}-${endPos}=Q');

      // Check for check
      isInCheck = FenParser.isInCheck(board, isWhiteTurn);

      // Clear selection and possible moves
      selectedPosition = null;
      possibleMoves = [];

      notifyListeners();
    }
  }

  void promotePawn(int row, int col, String pieceType) {
    ChessPiece? pawn = board[row][col];
    if (pawn != null && pawn is Pawn) {
      ChessPiece? newPiece;

      switch (pieceType) {
        case 'queen':
          newPiece = Queen(isWhite: pawn.isWhite);
          break;
        case 'rook':
          newPiece = Rook(isWhite: pawn.isWhite);
          break;
        case 'bishop':
          newPiece = Bishop(isWhite: pawn.isWhite);
          break;
        case 'knight':
          newPiece = Knight(isWhite: pawn.isWhite);
          break;
      }

      if (newPiece != null) {
        board[row][col] = newPiece;
        notifyListeners();
      }
    }
  }

  bool _isGameOver() {
    // Check for checkmate or stalemate
    bool noLegalMoves = true;

    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece.isWhite == isWhiteTurn) {
          List<List<int>> moves = piece.validMoves(r, c, board);

          for (var move in moves) {
            if (!FenParser.moveWouldLeaveKingInCheck(
                board, piece, r, c, move[0], move[1])) {
              noLegalMoves = false;
              break;
            }
          }

          if (!noLegalMoves) break;
        }
      }
      if (!noLegalMoves) break;
    }

    if (noLegalMoves) {
      if (isInCheck) {
        statusMessage =
            isWhiteTurn ? "Checkmate! Black wins!" : "Checkmate! White wins!";
      } else {
        statusMessage = "Stalemate! Game is a draw.";
      }
      return true;
    }

    return false;
  }

  void resetGame() {
    _initializeGame();
    selectedPosition = null;
    possibleMoves = [];
    lastMove = null;
    moveHistory = [];
    statusMessage = null;
    isInCheck = false;
    notifyListeners();
  }
}
