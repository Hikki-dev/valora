import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/onboarding_controller.dart';
import 'onboarding_content.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  final bool isFull;
  const OnboardingOverlay({super.key, this.isFull = true});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final contents = widget.isFull ? OnboardingContent.features : OnboardingContent.changelog;
    final isLastPage = _currentPage == contents.length - 1;

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentPage + 1} of ${contents.length}',
                    style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => ref.read(onboardingControllerProvider.notifier).completeOnboarding(),
                      child: const Text('Skip intro', style: TextStyle(color: Colors.white54, fontSize: 13)),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: contents.length,
                itemBuilder: (context, index) {
                  final content = contents[index];
                  return _buildSlide(content);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildDotsIndicator(contents.length),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('← Back', style: TextStyle(color: Colors.white)),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              ref.read(onboardingControllerProvider.notifier).completeOnboarding();
                            } else {
                              _pageController.nextPage(duration: 300.ms, curve: Curves.easeInOut);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isLastPage ? Colors.amber : Colors.white10,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isLastPage ? 'Go to Valora →' : 'Next →',
                            style: TextStyle(color: isLastPage ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSlide(OnboardingContent content) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
             if (content.preview != null) ...[
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: content.preview,
                  ),
                )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut)
                .animate()
                .scale(delay: 200.ms, duration: 600.ms, curve: Curves.easeOutBack)
                .fadeIn(delay: 200.ms, duration: 400.ms),
                const SizedBox(height: 48),
             ] else ...[
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: content.icon,
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
             ],
             Text(
               content.title,
               style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13),
             ),
             const SizedBox(height: 12),
             Text(
               content.subtitle,
               style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
             ),
             const SizedBox(height: 16),
             Text(
               content.description,
               style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.5),
             ),
             const SizedBox(height: 24),
             ...content.bulletPoints.map((point) => Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   const Padding(
                     padding: EdgeInsets.only(top: 6.0),
                     child: Icon(Icons.circle, color: Colors.amber, size: 6),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       point, 
                       style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)
                     )
                   ),
                 ],
               ),
             )),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: 300.ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
