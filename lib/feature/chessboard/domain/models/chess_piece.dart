import 'package:chess316/feature/chessboard/domain/models/chess_piece_enum.dart';

class ChessPiece {
  final ChessPieceType type;
  final String icon;
  final bool isWhite;

  ChessPiece({
    required this.type,
    required this.icon,
    required this.isWhite,
  });
}
