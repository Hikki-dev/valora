import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../controllers/onboarding_controller.dart';
import 'onboarding_content.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  final bool isFull;
  final int lastSeenCount;
  const OnboardingOverlay({super.key, this.isFull = true, this.lastSeenCount = 0});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = textColor.withOpacity(0.6);
    final primaryColor = Colors.amber;
    
    List<OnboardingContent> contents;
    if (widget.isFull) {
      contents = OnboardingContent.features;
    } else {
      // Show only items the user hasn't seen yet
      final allChangelog = OnboardingContent.changelog;
      if (widget.lastSeenCount < allChangelog.length) {
        contents = allChangelog.sublist(widget.lastSeenCount);
      } else {
        contents = [];
      }
    }

    if (contents.isEmpty) {
       // Safety check: if no new content, just complete it
       WidgetsBinding.instance.addPostFrameCallback((_) {
         ref.read(onboardingControllerProvider.notifier).completeOnboarding();
       });
       return const SizedBox.shrink();
    }

    final isLastPage = _currentPage == contents.length - 1;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor.withOpacity(0.98),
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
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  if (!isLastPage)
                    TextButton(
                      onPressed: () => ref.read(onboardingControllerProvider.notifier).completeOnboarding(),
                      child: Text('Skip intro', style: TextStyle(color: secondaryTextColor, fontSize: 13)),
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
                  return _buildSlide(content, textColor, secondaryTextColor, primaryColor);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildDotsIndicator(contents.length, primaryColor, textColor),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pageController.previousPage(duration: 300.ms, curve: Curves.easeInOut),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: textColor.withOpacity(0.1)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('← Back', style: TextStyle(color: textColor)),
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
                            backgroundColor: isLastPage ? primaryColor : textColor.withOpacity(0.05),
                             elevation: 0,
                             padding: const EdgeInsets.symmetric(vertical: 16),
                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(
                            isLastPage ? 'Go to Valora →' : 'Next →',
                            style: TextStyle(
                              color: isLastPage ? Colors.black : textColor, 
                              fontWeight: FontWeight.bold
                            ),
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

  Widget _buildSlide(OnboardingContent content, Color textColor, Color secondaryTextColor, Color primaryColor) {
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
                          color: Colors.black.withOpacity(0.3),
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
                      color: textColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: textColor.withOpacity(0.1)),
                    ),
                    child: content.icon,
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                const SizedBox(height: 32),
             ],
             Text(
               content.title,
               style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800, letterSpacing: 2, fontSize: 13),
             ),
             const SizedBox(height: 12),
             Text(
               content.subtitle,
               style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 28, letterSpacing: -1),
             ),
             const SizedBox(height: 16),
             Text(
               content.description,
               style: TextStyle(color: secondaryTextColor, fontSize: 15, height: 1.5),
             ),
             const SizedBox(height: 24),
             ...content.bulletPoints.map((point) => Padding(
               padding: const EdgeInsets.only(bottom: 12.0),
               child: Row(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Padding(
                     padding: const EdgeInsets.only(top: 6.0),
                     child: Icon(Icons.circle, color: primaryColor, size: 6),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       point, 
                       style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)
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

  Widget _buildDotsIndicator(int length, Color primaryColor, Color textColor) {
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
            color: isActive ? primaryColor : textColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
