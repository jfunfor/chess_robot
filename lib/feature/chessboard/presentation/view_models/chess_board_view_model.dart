import 'dart:async';

import 'package:flutter/cupertino.dart';

class ChessBoardViewModel extends ChangeNotifier {
  late Timer _timer;
  bool _showBorder = false;
  bool _isSelected = false;

  bool get isSelected => _isSelected;
  bool get showBoarder => _showBorder;

  set isSelected(bool value) {
    _isSelected = value;
    if (_isSelected) {
      _startTimer();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      _showBorder = !_showBorder;
      notifyListeners();
    });
  }

  void _stopTimer() {
    _timer.cancel();
    _showBorder = false;
  }
}
