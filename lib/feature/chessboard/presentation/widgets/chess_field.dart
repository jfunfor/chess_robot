import 'package:chess316/core/styles/colors.dart';
import 'package:flutter/material.dart';

import '../../domain/models/chess_pieces.dart';

class ChessField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    Color getColor() {
      if (isFilled && !isValidMove) {
        return AppColors.lightBrown;
      } else {
        if (isFilled && isValidMove) {
          return AppColors.darkBrown.withOpacity(0.4).withGreen(255);
        } else {
          if (!isFilled && !isValidMove) {
            return AppColors.darkBrown;
          } else {
            return AppColors.darkBrown.withOpacity(0.4).withGreen(255);
          }
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            margin: EdgeInsets.all(isValidMove ? 4 : 0),
            decoration: BoxDecoration(
              color: getColor(),
            ),
            child: piece != null
                ? Transform.scale(
                    scale: isSelected ? 1.2 : 1,
                    child: Transform.translate(
                      offset: Offset(0, isSelected ? -8 : 0),
                      child: Image.asset(
                        piece!.icon,
                        color:
                            piece!.isWhite ? AppColors.white : AppColors.black,
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
