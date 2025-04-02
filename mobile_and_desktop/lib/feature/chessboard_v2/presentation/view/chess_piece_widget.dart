import 'package:chess316/feature/chessboard_v2/domain/models/chess_pieces.dart';
import 'package:flutter/material.dart';

/// Widget for displaying a chess piece with appropriate styling
class ChessPieceWidget extends StatelessWidget {
  final ChessPiece piece;
  final double size;
  final bool isSelected;
  final bool isHighlighted;

  const ChessPieceWidget({
    Key? key,
    required this.piece,
    this.size = 40.0,
    this.isSelected = false,
    this.isHighlighted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Optional highlight or selection indicator
          if (isSelected || isHighlighted)
            Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.yellow.withAlpha(128)
                    : Colors.lightBlue.withAlpha(77),
              ),
            ),
          // Piece symbol
          Text(
            _getPieceSymbol(),
            style: TextStyle(
              fontSize: size * 0.8,
              color: piece.isWhite ? Colors.white : Colors.black,
              shadows: [
                Shadow(
                  color: piece.isWhite ? Colors.black : Colors.white,
                  blurRadius: 2,
                  offset: const Offset(1, 1),
                ),
              ],
            ),
            semanticsLabel: _getPieceDescription(),
          ),
        ],
      ),
    );
  }

  /// Gets the Unicode chess symbol for the piece
  String _getPieceSymbol() {
    if (piece is Pawn) return piece.isWhite ? '♙' : '♟';
    if (piece is Rook) return piece.isWhite ? '♖' : '♜';
    if (piece is Knight) return piece.isWhite ? '♘' : '♞';
    if (piece is Bishop) return piece.isWhite ? '♗' : '♝';
    if (piece is Queen) return piece.isWhite ? '♕' : '♛';
    if (piece is King) return piece.isWhite ? '♔' : '♚';
    return '?';
  }

  /// Gets a descriptive name for accessibility
  String _getPieceDescription() {
    String color = piece.isWhite ? "White" : "Black";
    String type = "Unknown";

    if (piece is Pawn) {
      type = "Pawn";
    } else if (piece is Rook) {
      type = "Rook";
    } else if (piece is Knight) {
      type = "Knight";
    } else if (piece is Bishop) {
      type = "Bishop";
    } else if (piece is Queen) {
      type = "Queen";
    } else if (piece is King) {
      type = "King";
    }

    return "$color $type";
  }
}
