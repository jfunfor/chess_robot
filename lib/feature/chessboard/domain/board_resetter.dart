import 'dart:collection';

abstract class BoardReSetter {
  static final Queue<BoardEvent> _moves = Queue();

  static void addMove({
    required int boardFrom,
    required int boardTo,
    required int positionTo,
    required int positionFrom,
  }) {
    _moves.addFirst(BoardEvent(
        boardFrom: boardFrom,
        boardTo: boardTo,
        positionTo: positionTo,
        positionFrom: positionFrom));
  }

  static void reset(Future<void> Function(BoardEvent) reSetter) async {
    for (final move in _moves) {
      final reversedMove = BoardEvent(
          boardFrom: move.boardTo,
          boardTo: move.boardFrom,
          positionTo: move.positionFrom,
          positionFrom: move.positionTo);
     await reSetter.call(reversedMove);
    }
    _moves.clear();
  }
}

class BoardEvent {
  final int positionFrom;
  final int positionTo;
  final int boardFrom;
  final int boardTo;

  const BoardEvent({
    required this.boardFrom,
    required this.boardTo,
    required this.positionTo,
    required this.positionFrom,
  });

  @override
  String toString() {
    return '{$positionTo, $positionFrom, $boardTo, $boardFrom}';
  }
}
