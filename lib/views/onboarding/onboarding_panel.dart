import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/onboarding_controller.dart';
import '../../core/theme.dart';
import 'onboarding_content.dart';

class OnboardingPanel extends ConsumerWidget {
  final List<OnboardingContent> contents;

  const OnboardingPanel({super.key, required this.contents});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: AppTheme.surface1,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 40,
            offset: Offset(-10, 0),
          ),
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
                  const Text(
                    'WHAT\'S NEW',
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => ref.read(onboardingControllerProvider.notifier).completeOnboarding(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: contents.length,
                separatorBuilder: (_, _ ) => const SizedBox(height: 32),
                itemBuilder: (context, index) {
                  final item = contents[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface2,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconTheme(
                          data: const IconThemeData(color: AppTheme.accentAmber, size: 24),
                          child: item.icon,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Syne',
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...item.bulletPoints.map((point) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: AppTheme.accentAmber, fontWeight: FontWeight.bold)),
                            Expanded(child: Text(point, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                          ],
                        ),
                      )),
                    ],
                  ).animate().fadeIn(delay: (index * 100).ms, duration: 400.ms).slideX(begin: 0.1, end: 0);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: () => ref.read(onboardingControllerProvider.notifier).completeOnboarding(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text('GOT IT', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Syne')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
