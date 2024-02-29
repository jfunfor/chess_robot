import 'package:chess316/core/styles/colors.dart';
import 'package:chess316/feature/chessboard/domain/models/chess_piece.dart';
import 'package:flutter/material.dart';

class ChessField extends StatefulWidget {
  final bool isFilled;
  final ChessPiece? piece;
  final Function() onTap;
  final bool isSelected;

  const ChessField({
    Key? key,
    required this.isFilled,
    this.piece,
    required this.onTap,
    this.isSelected = false,
  }) : super(key: key);

  @override
  _ChessFieldState createState() => _ChessFieldState();
}

class _ChessFieldState extends State<ChessField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.decelerate,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChessField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      _startAnimation();
    }
  }

  void _startAnimation() {
    _controller
      ..forward(from: 0)
      ..reverse(from: 1);
  }

  // bool transformAsTypeOfPiece(ChessPiece? piece){
  //
  // }

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
                  widget.isFilled ? AppColors.lightBrown : AppColors.darkBrown,
            ),
            child: widget.piece != null
                ? Transform.scale(
                    scale: widget.isSelected ? 1.2 : 1,
                    child: Transform.translate(
                      offset: Offset(
                          0, widget.isSelected ? widget.piece!.isWhite ? -8.0 * _animation.value : 8.0 * _animation.value : 0),
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
