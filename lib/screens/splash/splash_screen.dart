import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      context.go('/auth');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return CustomPaint(
              size: const Size(200, 200),
              painter: _ChatbotPainter(
                progress: _animation.value,
                color: Theme.of(context).colorScheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ChatbotPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ChatbotPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Draw animated circle
    canvas.drawCircle(
      center,
      radius * progress,
      paint,
    );

    // Draw animated chat bubble
    final bubblePath = Path();
    final bubbleWidth = radius * 0.8;
    final bubbleHeight = radius * 0.6;
    final bubbleLeft = center.dx - bubbleWidth / 2;
    final bubbleTop = center.dy - bubbleHeight / 2;

    bubblePath.moveTo(bubbleLeft, bubbleTop);
    bubblePath.lineTo(bubbleLeft + bubbleWidth * progress, bubbleTop);
    bubblePath.lineTo(bubbleLeft + bubbleWidth * progress, bubbleTop + bubbleHeight * progress);
    bubblePath.lineTo(bubbleLeft + bubbleWidth * 0.5, bubbleTop + bubbleHeight * progress);
    bubblePath.lineTo(bubbleLeft + bubbleWidth * 0.4, bubbleTop + bubbleHeight * progress + 10);
    bubblePath.lineTo(bubbleLeft + bubbleWidth * 0.3, bubbleTop + bubbleHeight * progress);
    bubblePath.lineTo(bubbleLeft, bubbleTop + bubbleHeight * progress);
    bubblePath.close();

    canvas.drawPath(bubblePath, paint);

    // Draw animated dots
    final dotRadius = radius * 0.1;
    final dotSpacing = radius * 0.3;
    final dotsCount = 3;

    for (var i = 0; i < dotsCount; i++) {
      final dotX = center.dx - dotSpacing + (i * dotSpacing);
      final dotY = center.dy + radius * 0.3;
      
      canvas.drawCircle(
        Offset(dotX, dotY),
        dotRadius * progress,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ChatbotPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
} 