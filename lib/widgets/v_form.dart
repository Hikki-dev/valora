import 'package:flutter/material.dart';
import '../core/tokens.dart';
import '../models/game.dart';
import 'comic.dart';

/// Labelled text field: label above (never placeholder-only), hard border, inline helper/error.
class VField extends StatelessWidget {
  const VField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.helper,
    this.errorText,
    this.keyboardType,
    this.maxLines = 1,
    this.prefixText,
    this.onChanged,
    this.optional = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? prefixText;
  final ValueChanged<String>? onChanged;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final hasError = errorText != null;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.zero, borderSide: BorderSide(color: c, width: 2));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(text: label, style: VText.body(13, t.text, weight: FontWeight.w900)),
          if (optional)
            TextSpan(
                text: '  optional',
                style: VText.body(12, t.muted, weight: FontWeight.w500)),
        ])),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: VText.body(16, t.text, weight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: VText.body(16, t.muted.withValues(alpha: 0.7), weight: FontWeight.w500),
            prefixText: prefixText,
            prefixStyle: VText.body(16, t.text, weight: FontWeight.w900),
            filled: true,
            fillColor: t.bg,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: border(hasError ? t.danger : t.soft),
            focusedBorder: border(hasError ? t.danger : t.line),
          ),
        ),
        if (hasError || helper != null) ...[
          const SizedBox(height: 4),
          Text(errorText ?? helper!,
              style: VText.body(12, hasError ? t.danger : t.muted,
                  weight: hasError ? FontWeight.w900 : FontWeight.w500)),
        ],
      ],
    );
  }
}

/// Frame for bottom sheets / dialogs: surface, heavy top border, handle, eyebrow + title + close.
class VSheetFrame extends StatelessWidget {
  const VSheetFrame({
    super.key,
    required this.title,
    required this.child,
    this.eyebrow,
    this.onClose,
  });

  final String title;
  final String? eyebrow;
  final Widget child;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: wide ? 560 : double.infinity),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(
              top: BorderSide(color: t.line, width: 3),
              left: wide ? BorderSide(color: t.line, width: 3) : BorderSide.none,
              right: wide ? BorderSide(color: t.line, width: 3) : BorderSide.none,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 48, height: 5, color: t.soft),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (eyebrow != null)
                            Text(eyebrow!,
                                style: VText.label(13, t.muted, spacing: 2)),
                          Text(title, style: VText.display(24, t.text)),
                        ],
                      ),
                    ),
                    PressableBox(
                      shadowOffset: 0,
                      padding: EdgeInsets.zero,
                      minHeight: 44,
                      semanticLabel: 'Close',
                      onTap: onClose ?? () => Navigator.maybePop(context),
                      child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.close_rounded, color: t.text)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Condition picker in plain language ("CIB" explained).
class VConditionPicker extends StatelessWidget {
  const VConditionPicker({super.key, required this.value, required this.onChanged});
  final GameCondition value;
  final ValueChanged<GameCondition> onChanged;

  static const _options = [
    (GameCondition.loose, 'Game only'),
    (GameCondition.cib, 'Complete'),
    (GameCondition.new_, 'Sealed'),
  ];

  static String helpFor(GameCondition c) => switch (c) {
        GameCondition.loose => 'Just the disc or cartridge. No case, no manual.',
        GameCondition.cib || GameCondition.boxed =>
          'Game + case + manual. Collector sites call this “CIB” (complete in box).',
        GameCondition.new_ => 'Brand new, factory shrink-wrap still on.',
      };

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final current = value == GameCondition.boxed ? GameCondition.cib : value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What shape is your copy in?',
            style: VText.body(13, t.text, weight: FontWeight.w900)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(border: Border.all(color: t.line, width: 2)),
          child: Row(
            children: [
              for (final o in _options)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: current == o.$1,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onChanged(o.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 48,
                        alignment: Alignment.center,
                        color: current == o.$1 ? t.text : Colors.transparent,
                        child: Text(o.$2,
                            style: VText.body(14, current == o.$1 ? t.bg : t.text,
                                weight: FontWeight.w900)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(helpFor(current),
              key: ValueKey(current),
              style: VText.body(13, t.muted, weight: FontWeight.w500)),
        ),
      ],
    );
  }
}
