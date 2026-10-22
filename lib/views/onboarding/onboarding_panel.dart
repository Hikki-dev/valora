import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/tokens.dart';
import '../../widgets/comic.dart';
import 'onboarding_content.dart';

class OnboardingPanel extends ConsumerWidget {
  final List<OnboardingContent> contents;

  const OnboardingPanel({super.key, required this.contents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(left: BorderSide(color: t.line, width: 3)),
        boxShadow: const [
          BoxShadow(
              color: Colors.black26, blurRadius: 30, offset: Offset(-8, 0)),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('What\u2019s new', style: VText.display(20, t.text)),
                  IconButton(
                    tooltip: 'Close',
                    icon: Icon(Icons.close, color: t.text),
                    onPressed: () => ref
                        .read(onboardingControllerProvider.notifier)
                        .completeOnboarding(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: contents.length,
                separatorBuilder: (_, __) => const SizedBox(height: 32),
                itemBuilder: (context, index) {
                  final item = contents[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: t.money,
                            border: Border.all(color: t.line, width: 2)),
                        child: IconTheme(
                          data: IconThemeData(color: t.onMoney, size: 24),
                          child: item.icon,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.subtitle,
                        style: VText.body(18, t.text, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: VText.body(14, t.muted, weight: FontWeight.w500)
                            .copyWith(height: 1.5),
                      ),
                      const SizedBox(height: 12),
                      ...item.bulletPoints.map((point) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ',
                                    style: VText.body(13, t.moneyText,
                                        weight: FontWeight.w900)),
                                Expanded(
                                    child: Text(point,
                                        style: VText.body(13, t.muted,
                                            weight: FontWeight.w500))),
                              ],
                            ),
                          )),
                    ],
                  )
                      .animate()
                      .fadeIn(delay: (index * 100).ms, duration: 400.ms)
                      .slideX(begin: 0.1, end: 0);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: PressableBox(
                onTap: () => ref
                    .read(onboardingControllerProvider.notifier)
                    .completeOnboarding(),
                color: t.money,
                minHeight: 52,
                semanticLabel: 'Got it',
                child: Text('Got it',
                    style: VText.body(15, t.onMoney, weight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
