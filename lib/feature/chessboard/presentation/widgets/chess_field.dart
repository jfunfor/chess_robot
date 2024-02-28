import 'package:chess316/core/styles/colors.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:chess316/feature/chessboard/presentation/view_models/chess_board_view_model.dart';
import 'package:flutter/material.dart';

class ChessField extends StatefulWidget {
  final bool isFilled;
  final ChessPiece? piece;
  final ChessBoardViewModel model;

  const ChessField({
    Key? key,
    required this.isFilled,
    this.piece,
    required this.model,
  }) : super(key: key);

  @override
  _ChessFieldState createState() => _ChessFieldState();
}

class _ChessFieldState extends State<ChessField> {
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.model,
      builder: (context, _) {
        return GestureDetector(
          onTap: (){
            widget.model.isSelected = !widget.model.isSelected;
          },
          child: Container(
            padding:
                !widget.model.showBoarder ? const EdgeInsets.all(4) : const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: widget.isFilled ? AppColors.lightBrown : AppColors.darkBrown,
              border: widget.model.showBoarder && widget.model.isSelected
                  ? Border.all(color: Colors.green, width: 2.0)
                  : null,
            ),
            child: widget.piece != null
                ? Image.asset(
                    widget.piece!.icon,
                    color:
                        widget.piece!.isWhite ? AppColors.white : AppColors.black,
                  )
                : null,
          ),
        );
      },
    );
  }
}
