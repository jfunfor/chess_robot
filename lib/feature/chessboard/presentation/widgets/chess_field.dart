import 'package:chess316/core/styles/colors.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:flutter/material.dart';

class ChessField extends StatefulWidget {
  final bool isFilled;
  final ChessPiece? piece;
  final Function() onTap;
  final bool isSelected;
  final bool isValidMove;

  const ChessField({
    Key? key,
    required this.isFilled,
    this.piece,
    required this.onTap,
    this.isSelected = false,
    this.isValidMove = false,
  }) : super(key: key);

  @override
  _ChessFieldState createState() => _ChessFieldState();
}

class _ChessFieldState extends State<ChessField> {

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color:
              (widget.isFilled && !widget.isValidMove) ? AppColors.lightBrown : widget.isValidMove ? AppColors.lightGreen: AppColors.darkBrown,
            ),
            child: widget.piece != null
                ? Transform.scale(
                    scale: widget.isSelected ? 1.2 : 1,
                    child: Transform.translate(
                      offset: Offset(0, widget.isSelected ? -8 : 0),
                      child: Image.asset(
                        widget.piece!.icon,
                        color: widget.piece!.isWhite
                            ? AppColors.white
                            : AppColors.black,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
