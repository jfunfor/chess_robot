// 在 lib/feature/chessboard_v2/presentation/chess_board_page.dart 文件中

import 'package:chess316/core/chess_icons/chess_icons.dart';
import 'package:chess316/feature/chessboard/data/service/chess_robot_service.dart';
import 'package:chess316/feature/chessboard_v2/presentation/view_models/chess_board_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChessBoardPageV2 extends StatelessWidget {
  final ChessRobotService robotService;

  const ChessBoardPageV2({Key? key, required this.robotService})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chess316 V2'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ChessBoardViewModel>().resetGame(),
            tooltip: 'Reset Game',
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Consumer<ChessBoardViewModel>(
            builder: (context, viewModel, child) {
              return Container(
                padding: const EdgeInsets.all(8.0),
                width: double.infinity,
                color: Colors.brown[200],
                child: Center(
                  child: Text(
                    viewModel.statusMessage ?? 'Welcome to Chess316 V2',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Chessboard
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(8.0),
                child: Consumer<ChessBoardViewModel>(
                  builder: (context, viewModel, child) {
                    return viewModel.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Board
                              AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 2),
                                  ),
                                  child: ChessBoardWidget(viewModel: viewModel),
                                ),
                              ),

                              // Promotion dialog if needed
                              if (viewModel.pendingPromotion != null)
                                PromotionSelector(viewModel: viewModel),
                            ],
                          );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Game info
          Consumer<ChessBoardViewModel>(
            builder: (context, viewModel, child) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Turn: ${viewModel.isWhiteTurn ? 'White' : 'Black'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 16),
                    if (viewModel.isInCheck)
                      Text(
                        'CHECK!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ChessBoardWidget extends StatelessWidget {
  final ChessBoardViewModel viewModel;

  const ChessBoardWidget({Key? key, required this.viewModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
      ),
      itemCount: 64,
      itemBuilder: (context, index) {
        // Convert index to row, col (0,0 is top-left)
        final row = index ~/ 8;
        final col = index % 8;

        // Determine if it's a dark or light square
        final isDarkSquare = (row + col) % 2 == 1;

        // Check if the square is selected
        final isSelected = viewModel.selectedPosition != null &&
            viewModel.selectedPosition![0] == row &&
            viewModel.selectedPosition![1] == col;

        // Check if the square is a possible move
        final isPossibleMove = viewModel.possibleMoves.any(
          (move) => move[0] == row && move[1] == col,
        );

        // Check if it's part of the last move
        final isLastMove = viewModel.lastMove != null &&
            ((viewModel.lastMove![0] == row && viewModel.lastMove![1] == col) ||
                (viewModel.lastMove![2] == row &&
                    viewModel.lastMove![3] == col));

        // Get the piece at this position
        final piece = viewModel.board[row][col];

        return GestureDetector(
          onTap: () {
            // If a piece is already selected and this is a valid move, move the piece
            if (viewModel.selectedPosition != null &&
                viewModel.possibleMoves
                    .any((move) => move[0] == row && move[1] == col)) {
              viewModel.movePiece(row, col);
            }
            // Otherwise, select the piece if it belongs to the player
            else if (piece != null &&
                ((viewModel.playerColor == 'w' && piece.isWhite) ||
                    (viewModel.playerColor == 'b' && !piece.isWhite))) {
              viewModel.selectPiece(row, col);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green[300]
                  : isPossibleMove
                      ? (isDarkSquare
                          ? Colors.lightGreen.withAlpha(153)
                          : Colors.lightGreen.withAlpha(204))
                      : isLastMove
                          ? (isDarkSquare
                              ? Colors.amber[300]
                              : Colors.amber[200])
                          : (isDarkSquare
                              ? Colors.brown[700]
                              : Colors.brown[200]),
              border: isPossibleMove && piece != null
                  ? Border.all(color: Colors.red, width: 2)
                  : null,
            ),
            child: piece != null
                ? Center(
                    child: Image.asset(
                      piece.icon,
                      width: 36,
                      height: 36,
                      color: piece.isWhite ? Colors.white : Colors.black,
                      colorBlendMode: BlendMode.srcATop,
                    ),
                  )
                : isPossibleMove
                    ? Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green[700],
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
          ),
        );
      },
    );
  }
}

class PromotionSelector extends StatelessWidget {
  final ChessBoardViewModel viewModel;

  const PromotionSelector({Key? key, required this.viewModel})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine which color pieces to show
    bool isWhite = true;

    if (viewModel.pendingPromotion != null) {
      final piece = viewModel.board[viewModel.pendingPromotion![0]]
          [viewModel.pendingPromotion![1]];
      if (piece != null) {
        isWhite = piece.isWhite;
      }
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Promote pawn to:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPromotionOption(ChessIcons.queen, 'queen', isWhite),
              _buildPromotionOption(ChessIcons.rook, 'rook', isWhite),
              _buildPromotionOption(ChessIcons.bishop, 'bishop', isWhite),
              _buildPromotionOption(ChessIcons.knight, 'knight', isWhite),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionOption(String icon, String piece, bool isWhite) {
    return GestureDetector(
      onTap: () => viewModel.promotePawn(piece),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.brown[200],
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: Image.asset(
            icon,
            width: 36,
            height: 36,
            color: isWhite ? Colors.white : Colors.black,
            colorBlendMode: BlendMode.srcATop,
          ),
        ),
      ),
    );
  }
}
