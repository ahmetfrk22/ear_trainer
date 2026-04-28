import 'package:flutter/material.dart';

/// Piyanoyu ekranın en altına "tam oturtur" ve
/// gesture/navigation bar alanını da arka planla doldurur.
class PianoDock extends StatelessWidget {
  final Widget child;

  const PianoDock({super.key, required this.child});

  /// `PianoKeyboard` için yaklaşık yükseklik (oktav satırı + tuşlar).
  static const double baseHeight = 190.0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Material(
      color: const Color(0xFF1E1A2E),
      elevation: 12,
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: child,
      ),
    );
  }
}

