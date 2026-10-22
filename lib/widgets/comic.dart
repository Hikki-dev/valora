import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/tokens.dart';

const Color kInk = Color(0xFF15121F);

/// Bordered box with a hard (un-blurred) offset shadow: the basic "manga panel".
class HardBox extends StatelessWidget {
  const HardBox({
    super.key,
    required this.child,
    this.color,
    this.borderWidth = 2,
    this.shadowOffset = 4,
    this.shadowColor,
    this.borderColor,
    this.padding,
  });

  final Widget child;
  final Color? color;
  final double borderWidth;
  final double shadowOffset;
  final Color? shadowColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? t.surface,
        border: Border.all(color: borderColor ?? t.line, width: borderWidth),
        boxShadow: shadowOffset > 0
            ? [
                BoxShadow(
                    color: shadowColor ?? t.shadow2,
                    offset: Offset(shadowOffset, shadowOffset),
                    blurRadius: 0)
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// A [HardBox] that presses in on tap (moves down-right, shadow collapses) and
/// lifts on hover (desktop). 44px minimum height for touch targets.
class PressableBox extends StatefulWidget {
  const PressableBox({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.shadowOffset = 4,
    this.shadowColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
    this.minHeight = 44,
    this.semanticLabel,
    this.onPressStart,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Fires the moment a finger/mouse goes down (use to warm data before navigation).
  final VoidCallback? onPressStart;
  final Color? color;
  final double shadowOffset;
  final Color? shadowColor;
  final EdgeInsetsGeometry padding;
  final double minHeight;
  final String? semanticLabel;

  @override
  State<PressableBox> createState() => _PressableBoxState();
}

class _PressableBoxState extends State<PressableBox> {
  bool _down = false;
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final so = widget.shadowOffset;
    final shadow = _down ? 0.0 : (_hover ? so + 2 : so);
    final shift = _down ? so : (_hover ? -2.0 : 0.0);

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) {
            widget.onPressStart?.call();
            setState(() => _down = true);
          },
          onTapUp: (_) => setState(() => _down = false),
          onTapCancel: () => setState(() => _down = false),
          child: AnimatedContainer(
            duration:
                reduce ? Duration.zero : const Duration(milliseconds: 110),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(shift, shift, 0),
            constraints: BoxConstraints(minHeight: widget.minHeight),
            padding: widget.padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color ?? t.surface,
              border: Border.all(color: t.line, width: 2),
              boxShadow: shadow > 0
                  ? [
                      BoxShadow(
                          color: widget.shadowColor ?? t.shadow2,
                          offset: Offset(shadow, shadow),
                          blurRadius: 0)
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Text with a stroke around it (comic sound effects: POW!, K.O.!).
class OutlinedText extends StatelessWidget {
  const OutlinedText(
    this.text, {
    super.key,
    required this.size,
    required this.fill,
    this.stroke = kInk,
    this.strokeWidth = 4,
    this.family = VFont.display,
    this.textAlign = TextAlign.center,
  });

  final String text;
  final double size;
  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final String family;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Text(text,
            textAlign: textAlign,
            style: TextStyle(
              fontFamily: family,
              fontSize: size,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeJoin = StrokeJoin.round
                ..color = stroke,
            )),
        Text(text,
            textAlign: textAlign,
            style: TextStyle(fontFamily: family, fontSize: size, color: fill)),
      ],
    );
  }
}

/// Jagged comic burst shape.
class StarburstPainter extends CustomPainter {
  StarburstPainter({
    required this.fill,
    this.stroke = kInk,
    this.points = 11,
    this.innerRatio = 0.62,
    this.strokeWidth = 3,
  });

  final Color fill;
  final Color stroke;
  final int points;
  final double innerRatio;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final ro = math.min(size.width, size.height) / 2 - strokeWidth;
    final ri = ro * innerRatio;
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final r = i.isEven ? ro : ri;
      final a = -math.pi / 2 + i * math.pi / points;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = fill);
    canvas.drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(StarburstPainter old) =>
      old.fill != fill || old.stroke != stroke || old.points != points;
}

/// A starburst with a sound-effect word on it.
class StarburstBadge extends StatelessWidget {
  const StarburstBadge({
    super.key,
    required this.text,
    this.size = 72,
    this.fill = const Color(0xFFFFC247),
    this.textColor = const Color(0xFFD81E5B),
    this.textSize = 16,
    this.rotation = -0.12,
  });

  final String text;
  final double size;
  final Color fill;
  final Color textColor;
  final double textSize;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                  size: Size.square(size),
                  painter: StarburstPainter(fill: fill)),
              Transform.rotate(
                angle: rotation,
                child: OutlinedText(text,
                    size: textSize,
                    fill: textColor,
                    strokeWidth: textSize * 0.28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Valora's original hero, drawn natively in a 42x56 unit box.
/// [armEnd] is where the raised arm points (null = no arm).
class HeroPainter extends CustomPainter {
  HeroPainter({this.armEnd = const Offset(38, 12)});
  final Offset? armEnd;

  static const _blue = Color(0xFF2B5CFF);
  static const _navy = Color(0xFF1D3FBF);
  static const _skin = Color(0xFFF2C9A0);
  static const _gold = Color(0xFFFFC247);
  static const _cape = Color(0xFFD81E5B);

  Paint _f(Color c) => Paint()..color = c;
  Paint _s(double w) => Paint()
    ..color = kInk
    ..style = PaintingStyle.stroke
    ..strokeWidth = w
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 42, size.height / 56);
    canvas.save();
    canvas.scale(s);

    final cape = Path()
      ..moveTo(18, 22)
      ..cubicTo(8, 27, 5, 38, 2, 47)
      ..lineTo(20, 47)
      ..close();
    canvas.drawPath(cape, _f(_cape));
    canvas.drawPath(cape, _s(1.8));

    for (final x in [14.0, 21.0]) {
      final leg = Rect.fromLTWH(x, 40, 5, 14);
      canvas.drawRect(leg, _f(_navy));
      canvas.drawRect(leg, _s(1.5));
    }

    final body = Path()
      ..moveTo(13, 22)
      ..lineTo(29, 22)
      ..lineTo(32, 42)
      ..lineTo(10, 42)
      ..close();
    canvas.drawPath(body, _f(_blue));
    canvas.drawPath(body, _s(2));

    final end = armEnd;
    if (end != null) {
      canvas.drawLine(const Offset(30, 26), end, _s(7));
      canvas.drawLine(
          const Offset(30, 26),
          end,
          Paint()
            ..color = _blue
            ..strokeWidth = 4.4
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(end, 3.4, _f(_skin));
      canvas.drawCircle(end, 3.4, _s(1.5));
    }

    canvas.drawCircle(const Offset(21, 14), 7, _f(_skin));
    canvas.drawCircle(const Offset(21, 14), 7, _s(2));
    canvas.drawRect(const Rect.fromLTWH(14, 12, 14, 4), _f(kInk));
    final eye = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(16, 14), const Offset(20, 13), eye);
    canvas.drawLine(const Offset(26, 14), const Offset(22, 13), eye);

    canvas.drawCircle(const Offset(21, 31), 4.5, _f(_gold));
    canvas.drawCircle(const Offset(21, 31), 4.5, _s(1.5));
    final tp = TextPainter(
      text: const TextSpan(
          text: 'V',
          style:
              TextStyle(fontFamily: VFont.display, fontSize: 7, color: kInk)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(21 - tp.width / 2, 31 - tp.height / 2));

    canvas.restore();
  }

  @override
  bool shouldRepaint(HeroPainter old) => old.armEnd != armEnd;
}

class HeroFigure extends StatelessWidget {
  const HeroFigure(
      {super.key, this.width = 60, this.armEnd = const Offset(38, 12)});
  final double width;
  final Offset? armEnd;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, width * 56 / 42),
        painter: HeroPainter(armEnd: armEnd),
      ),
    );
  }
}

/// Small repeating dots: the "screentone" texture.
class HalftonePainter extends CustomPainter {
  HalftonePainter({required this.color, this.spacing = 7, this.radius = 1.3});
  final Color color;
  final double spacing;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = spacing / 2; y < size.height; y += spacing) {
      for (var x = spacing / 2; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), radius, p);
      }
    }
  }

  @override
  bool shouldRepaint(HalftonePainter old) =>
      old.color != color || old.spacing != spacing;
}

/// Speed-line fan radiating from [origin] (0..1 of the box).
class RaysPainter extends CustomPainter {
  RaysPainter({required this.color, this.origin = const Offset(0.5, 0.4)});
  final Color color;
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * origin.dx, size.height * origin.dy);
    final far = size.longestSide * 2;
    final p = Paint()..color = color;
    const step = 9 * math.pi / 180;
    const width = 2 * math.pi / 180;
    for (var a = 0.0; a < 2 * math.pi; a += step) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + far * math.cos(a), c.dy + far * math.sin(a))
        ..lineTo(
            c.dx + far * math.cos(a + width), c.dy + far * math.sin(a + width))
        ..close();
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(RaysPainter old) =>
      old.color != color || old.origin != origin;
}
