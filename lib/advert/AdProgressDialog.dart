
import 'dart:async';

import 'package:flutter/material.dart';

class AdProgressDialog extends StatefulWidget {
  final int completed;
  final int total;
  final String reason;
  final VoidCallback onTimerFinished;
  final VoidCallback onCancel;

  const AdProgressDialog({
    Key? key,
    required this.completed,
    required this.total,
    required this.onTimerFinished,
    required this.onCancel,
    required this.reason,
  }) : super(key: key);

  @override
  State<AdProgressDialog> createState() => _AdProgressDialogState();
}

class _AdProgressDialogState extends State<AdProgressDialog> {
  int _countdown = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown >= 1) {
        if (mounted) {
          setState(() {
            _countdown--;
          });
        }
      } else {
        _timer?.cancel();
        widget.onTimerFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1C23),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    value: _countdown / 3,
                    strokeWidth: 4,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white54),
                  ),
                ),
                const Icon(Icons.play_arrow, color: Colors.white, size: 30),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              "Playing next ad in $_countdown",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${widget.reason} with ${widget.total - widget.completed} more ads",
              style: const TextStyle(
                color: Color(0xFFF9C304),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF9C304), width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.completed / widget.total,
                      child: Container(
                        color: const Color(0xFFF9C304),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          "${widget.completed}/${widget.total} Ads",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2C313B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}