import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/tokens.dart';
import 'comic.dart';

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _lerp(double a, double b, double t) => a + (b - a) * t;
double _easeOut(double t) => 1 - math.pow(1 - t, 3).toDouble();

/// Three-panel animated comic (wind-up, impact, K.O.), looping every 4 seconds.
/// Original characters: Valora's hero vs. the hooded villain "Fake Prices".
/// With reduced motion on, all three panels show as a still.
class ComicFightStrip extends StatefulWidget {
  const ComicFightStrip({super.key, this.width = 310});
  final double width;

  @override
  State<ComicFightStrip> createState() => _ComicFightStripState();
}

class _ComicFightStripState extends State<ComicFightStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 4));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
      _c.value = 0.95;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Semantics(
      label:
          'Animated comic: the Valora hero punches the hooded villain Fake Prices, who is knocked out',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final v = _c.value;
              // Screen shake as the punch lands.
              var dx = 0.0, dy = 0.0;
              if (v > 0.33 && v < 0.41) {
                final k = (v - 0.33) / 0.08;
                dx = 3 * math.sin(k * 3 * math.pi) * (1 - k);
                dy = -2 * math.sin(k * 3 * math.pi + 1) * (1 - k);
              }
              final fade = 1 - _seg(v, 0.92, 1);
              final r1 = _seg(v, 0, 0.05);
              final r2a = _seg(v, 0.28, 0.34), r2b = _seg(v, 0.34, 0.38);
              final r3a = _seg(v, 0.58, 0.64), r3b = _seg(v, 0.64, 0.68);
              return Transform.translate(
                offset: Offset(dx, dy),
                child: SizedBox(
                  width: widget.width,
                  height: 150,
                  child: Row(
                    children: [
                      Expanded(
                        child: _Panel(
                          bg: const Color(0xFFFFC247),
                          caption: '1 · WIND-UP…',
                          opacity: r1 * fade,
                          scale: _lerp(0.8, 1, _easeOut(r1)),
                          shadow: t.shadow,
                          line: t.line,
                          art: CustomPaint(painter: _Panel1Painter(v)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Panel(
                          bg: const Color(0xFFFF5C8A),
                          caption: '2 · IMPACT!',
                          opacity: r2a * fade,
                          scale: _lerp(_lerp(0.7, 1.06, r2a), 1, r2b),
                          shadow: t.shadow,
                          line: t.line,
                          art: CustomPaint(painter: _Panel2Painter(v)),
                          overlay: const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 2,
                            child: Center(
                              child: OutlinedText('POW!',
                                  size: 26, fill: Color(0xFFF4EFE6)),
                            ),
                          ),
                          overlayOpacity: _seg(v, 0.34, 0.4) * fade,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _Panel(
                          bg: const Color(0xFF39E3FF),
                          caption: '3 · DOWN!',
                          opacity: r3a * fade,
                          scale: _lerp(_lerp(0.7, 1.06, r3a), 1, r3b),
                          shadow: t.shadow,
                          line: t.line,
                          art: CustomPaint(painter: _Panel3Painter(v)),
                          overlay: const Positioned(
                            left: 0,
                            right: 0,
                            bottom: 2,
                            child: Center(
                              child: OutlinedText('K.O.!',
                                  size: 26, fill: Color(0xFFFFC247)),
                            ),
                          ),
                          overlayOpacity: _seg(v, 0.64, 0.72) * fade,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.bg,
    required this.caption,
    required this.opacity,
    required this.scale,
    required this.art,
    required this.shadow,
    required this.line,
    this.overlay,
    this.overlayOpacity = 1,
  });

  final Color bg;
  final String caption;
  final double opacity;
  final double scale;
  final Widget art;
  final Color shadow;
  final Color line;
  final Widget? overlay;
  final double overlayOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: line, width: 3),
        boxShadow: [BoxShadow(color: shadow, offset: const Offset(4, 4))],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(scale: scale, child: art),
          ),
          if (overlay != null)
            Opacity(
                opacity: overlayOpacity.clamp(0.0, 1.0),
                child: Stack(children: [overlay!])),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE08A),
                border: Border(bottom: BorderSide(color: line, width: 3)),
              ),
              child: Text(caption,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                      fontFamily: VFont.label, fontSize: 10, color: kInk)),
            ),
          ),
        ],
      ),
    );
  }
}

void _tone(Canvas canvas, Size size, Color c) {
  final p = Paint()..color = c;
  for (var y = 3.0; y < size.height; y += 6) {
    for (var x = 3.0; x < size.width; x += 6) {
      canvas.drawCircle(Offset(x, y), 1.1, p);
    }
  }
}

Paint _stroke(double w) => Paint()
  ..color = kInk
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeJoin = StrokeJoin.round
  ..strokeCap = StrokeCap.round;

class _Panel1Painter extends CustomPainter {
  _Panel1Painter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    _tone(canvas, size, const Color(0x38151215));
    canvas.save();
    canvas.scale(size.width / 94, size.height / 150);
    // Hero leans back for the wind-up, then holds.
    final lean = -5 * math.pi / 180 * math.sin(math.pi * _seg(t, 0, 0.22));
    const hs = 1.9;
    canvas.translate(8, 36);
    canvas.translate(21 * hs, 56 * hs);
    canvas.rotate(lean);
    canvas.translate(-21 * hs, -56 * hs);
    canvas.scale(hs);
    HeroPainter(armEnd: const Offset(36, 30))
        .paint(canvas, const Size(42, 56));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Panel1Painter old) => old.t != t;
}

class _Panel2Painter extends CustomPainter {
  _Panel2Painter(this.t);
  final double t;

  static const _pts = [
    [47, 24], [55, 44], [76, 38], [70, 58], [90, 66], [68, 76], [78, 98],
    [56, 90], [47, 112], [38, 90], [16, 98], [26, 76], [4, 66], [24, 58],
    [18, 38], [39, 44]
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 94, size.height / 150);
    final lines = _stroke(2)..color = const Color(0x59151215);
    for (final l in [
      [0, 40, 94, 70], [0, 75, 94, 75], [0, 110, 94, 80], [0, 20, 94, 62], [0, 130, 94, 88]
    ]) {
      canvas.drawLine(Offset(l[0].toDouble(), l[1].toDouble()),
          Offset(l[2].toDouble(), l[3].toDouble()), lines);
    }

    // Starburst pops in as the fist lands.
    final b = t < 0.32
        ? 0.0
        : t < 0.38
            ? _lerp(0.3, 1.15, _easeOut(_seg(t, 0.32, 0.38)))
            : _lerp(1.15, 1.0, _seg(t, 0.38, 0.44));
    if (b > 0) {
      canvas.save();
      canvas.translate(47, 68);
      canvas.rotate(-6 * math.pi / 180);
      canvas.scale(b);
      canvas.translate(-47, -68);
      final path = Path();
      for (var i = 0; i < _pts.length; i++) {
        final p = Offset(_pts[i][0].toDouble(), _pts[i][1].toDouble());
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0xFFFFC247));
      canvas.drawPath(path, _stroke(3));
      canvas.restore();
    }

    // Fist flies in from the left.
    final fx = t < 0.28 ? -46.0 : _lerp(-46, 0, _easeOut(_seg(t, 0.28, 0.34)));
    final fs = t < 0.28
        ? 0.8
        : t < 0.34
            ? _lerp(0.8, 1.08, _seg(t, 0.28, 0.34))
            : _lerp(1.08, 1.0, _seg(t, 0.34, 0.4));
    canvas.save();
    canvas.translate(fx, 0);
    canvas.translate(30, 75);
    canvas.scale(fs);
    canvas.translate(-30, -75);
    final sleeve = RRect.fromRectAndRadius(
        const Rect.fromLTWH(-6, 62, 42, 26), const Radius.circular(8));
    final fist = RRect.fromRectAndRadius(
        const Rect.fromLTWH(30, 56, 34, 38), const Radius.circular(12));
    canvas.drawRRect(sleeve, Paint()..color = const Color(0xFF1D3FBF));
    canvas.drawRRect(sleeve, _stroke(3));
    canvas.drawRRect(fist, Paint()..color = const Color(0xFF2B5CFF));
    canvas.drawRRect(fist, _stroke(3));
    canvas.drawLine(const Offset(42, 62), const Offset(42, 88), _stroke(2));
    canvas.drawLine(const Offset(52, 62), const Offset(52, 88), _stroke(2));
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Panel2Painter old) => old.t != t;
}

class _Panel3Painter extends CustomPainter {
  _Panel3Painter(this.t);
  final double t;

  void _star(Canvas canvas, Offset c, double ro, double ri) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? ro : ri;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xFFFFC247));
    canvas.drawPath(path, _stroke(1.5));
  }

  @override
  void paint(Canvas canvas, Size size) {
    _tone(canvas, size, const Color(0x38151215));
    canvas.save();
    canvas.scale(size.width / 94, size.height / 150);
    final lines = _stroke(2)..color = const Color(0x59151215);
    for (final y in [70.0, 90.0, 110.0]) {
      canvas.drawLine(Offset(0, y), Offset(60, y - 6), lines);
    }

    // Villain is knocked back and spins away.
    final k = _easeOut(_seg(t, 0.58, 0.70));
    canvas.save();
    canvas.translate(_lerp(-16, 6, k), _lerp(0, -8, k));
    canvas.translate(58, 80);
    canvas.rotate(_lerp(0, -38, k) * math.pi / 180);
    canvas.translate(-58, -80);
    final body = Path()
      ..moveTo(40, 60)
      ..cubicTo(40, 40, 76, 40, 76, 60)
      ..lineTo(80, 112)
      ..lineTo(36, 112)
      ..close();
    canvas.drawPath(body, Paint()..color = const Color(0xFF3A2A5C));
    canvas.drawPath(body, _stroke(3));
    canvas.drawCircle(const Offset(58, 58), 12, Paint()..color = kInk);
    final eye = Paint()..color = const Color(0xFFFF2D55);
    canvas.drawCircle(const Offset(53, 58), 2.6, eye);
    canvas.drawCircle(const Offset(63, 58), 2.6, eye);
    const tag = Rect.fromLTWH(46, 86, 24, 14);
    canvas.drawRect(tag, Paint()..color = const Color(0xFFFFC247));
    canvas.drawRect(tag, _stroke(2));
    final tp = TextPainter(
      text: const TextSpan(
          text: r'$??',
          style: TextStyle(fontFamily: VFont.display, fontSize: 9, color: kInk)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(58 - tp.width / 2, 93 - tp.height / 2));
    canvas.restore();

    // Stars.
    final s = t < 0.64
        ? 0.0
        : t < 0.72
            ? _lerp(0.3, 1.1, _seg(t, 0.64, 0.72))
            : _lerp(1.1, 1.0, _seg(t, 0.72, 0.78));
    if (s > 0) {
      for (final c in const [Offset(14, 30), Offset(72, 22)]) {
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.scale(s);
        _star(canvas, Offset.zero, 8, 3.5);
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Panel3Painter old) => old.t != t;
}

/// Full loading screen: V mark, comic strip, segmented progress bar.
/// Pass [progress] (0..1) for real progress, or leave null for a looping sweep.
class ComicLoader extends StatelessWidget {
  const ComicLoader({
    super.key,
    this.label = 'NOW LOADING…',
    this.steps = const [],
    this.progress,
  });

  final String label;
  final List<LoaderStep> steps;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Semantics(
      liveRegion: true,
      label: label,
      child: Container(
        color: t.bg,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
                painter: RaysPainter(color: t.rays, origin: const Offset(0.5, 0.4))),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _VMark(),
                    const SizedBox(height: 16),
                    Text('VALORA',
                        style: VText.display(30, t.text, spacing: 4)),
                    const SizedBox(height: 4),
                    Text('ヴァローラ',
                        style: VText.label(14, t.muted, spacing: 3)),
                    const SizedBox(height: 22),
                    const ComicFightStrip(),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 290,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: VText.label(14, t.text, spacing: 1)),
                          const SizedBox(height: 8),
                          _Segments(progress: progress),
                          if (steps.isNotEmpty) const SizedBox(height: 12),
                          for (final s in steps) _StepRow(step: s),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoaderStep {
  const LoaderStep(this.text, {this.done = false, this.active = false});
  final String text;
  final bool done;
  final bool active;
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});
  final LoaderStep step;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final on = step.done || step.active;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: step.done ? t.money : Colors.transparent,
              border: Border.all(color: on ? t.line : t.soft, width: 2),
            ),
            child: step.done
                ? Text('✓', style: TextStyle(fontSize: 10, color: t.onMoney, fontWeight: FontWeight.w900))
                : null,
          ),
          const SizedBox(width: 10),
          Text(step.text, style: VText.body(13, on ? t.text : t.muted, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _VMark extends StatefulWidget {
  const _VMark();
  @override
  State<_VMark> createState() => _VMarkState();
}

class _VMarkState extends State<_VMark> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, -5 * Curves.easeInOut.transform(_c.value)),
          child: Transform.rotate(angle: -6 * math.pi / 180, child: child),
        ),
        child: SizedBox(
          width: 92,
          height: 92,
          child: Stack(
            children: [
              Positioned.fill(
                child: Transform.translate(
                  offset: const Offset(7, 7),
                  child: Container(
                    decoration: BoxDecoration(
                        color: t.money,
                        border: Border.all(color: t.line, width: 2)),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: t.surface,
                      border: Border.all(color: t.line, width: 4)),
                  child: Text('V', style: VText.display(60, t.text)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 12 skewed progress segments. [progress] null = looping sweep.
class _Segments extends StatefulWidget {
  const _Segments({this.progress});
  final double? progress;
  @override
  State<_Segments> createState() => _SegmentsState();
}

class _SegmentsState extends State<_Segments> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.progress == null && !MediaQuery.disableAnimationsOf(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Transform(
      transform: Matrix4.skewX(-0.24),
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final p = widget.progress;
          final filled = p != null ? (p.clamp(0.0, 1.0) * 12).round() : (_c.value * 15).floor();
          return Row(
            children: [
              for (var i = 0; i < 12; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Expanded(
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: p != null
                          ? (i < filled ? t.money : t.surface2)
                          : ((i - filled).abs() <= 2 || (filled > 12 && i < filled - 12 + 0)
                              ? t.money
                              : t.surface2),
                      border: Border.all(color: t.line, width: 1),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
