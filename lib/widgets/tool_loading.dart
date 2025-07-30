import 'package:flutter/material.dart';
import 'dart:math' as math;

class ToolLoadingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const ToolLoadingIndicator({
    Key? key,
    this.color = Colors.blue,
    this.size = 60.0,
  }) : super(key: key);

  @override
  State<ToolLoadingIndicator> createState() => _ToolLoadingIndicatorState();
}

class _ToolLoadingIndicatorState extends State<ToolLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Círculo de fundo
          Container(
            width: widget.size * 0.85,
            height: widget.size * 0.85,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
          ),

          // Engrenagem externa rotativa
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: GearPainter(
                    color: widget.color,
                    teeth: 8,
                  ),
                ),
              );
            },
          ),

          // Engrenagem interna rotativa (sentido oposto)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: -_controller.value * 4 * math.pi,
                child: CustomPaint(
                  size: Size(widget.size * 0.5, widget.size * 0.5),
                  painter: GearPainter(
                    color: widget.color,
                    teeth: 6,
                  ),
                ),
              );
            },
          ),

          // Chave de fenda no meio que pulsa
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: 0.7 + 0.3 * math.sin(_controller.value * 6 * math.pi),
                child: Transform.scale(
                  scale: 0.8 + 0.2 * math.sin(_controller.value * 6 * math.pi),
                  child: Icon(
                    Icons.build,
                    color: widget.color,
                    size: widget.size * 0.25,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class GearPainter extends CustomPainter {
  final Color color;
  final int teeth;

  GearPainter({
    required this.color,
    required this.teeth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double radius = size.width / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.15
      ..strokeCap = StrokeCap.round;

    // Desenha o círculo da engrenagem
    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.7,
      paint,
    );

    // Desenha os dentes da engrenagem
    final double toothLength = radius * 0.3;

    for (int i = 0; i < teeth; i++) {
      final double angle = (i / teeth) * 2 * math.pi;
      final double startX = centerX + math.cos(angle) * radius * 0.7;
      final double startY = centerY + math.sin(angle) * radius * 0.7;
      final double endX = centerX + math.cos(angle) * (radius * 0.7 + toothLength);
      final double endY = centerY + math.sin(angle) * (radius * 0.7 + toothLength);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}