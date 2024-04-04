import 'package:chess316/core/styles/colors.dart';
import 'package:flutter/material.dart';

class AlertDialogContent extends StatelessWidget {
  final VoidCallback onConfirmTap;

  const AlertDialogContent({
    super.key,
    required this.onConfirmTap,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(20.0).copyWith(top: 40),
      backgroundColor: Colors.brown[100],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Play again?',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(AppColors.darkBrown),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(AppColors.white),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
              const SizedBox(
                width: 20,
              ),
              OutlinedButton(
                onPressed: onConfirmTap,
                style: ButtonStyle(
                  backgroundColor:
                      MaterialStateProperty.all<Color>(AppColors.darkBrown),
                  foregroundColor:
                      MaterialStateProperty.all<Color>(AppColors.white),
                ),
                child: const Text('Yes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
