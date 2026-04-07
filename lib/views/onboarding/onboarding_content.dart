import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/onboarding_previews.dart';

class OnboardingContent {
  final String title;
  final String subtitle;
  final String description;
  final List<String> bulletPoints;
  final Widget icon;
  final Widget? preview;

  OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.bulletPoints,
    required this.icon,
    this.preview,
  });

  static List<OnboardingContent> get features => [
    OnboardingContent(
      title: 'FEATURE 01',
      subtitle: 'Your collection at a glance',
      description: 'The dashboard shows every platform you own games on, with live valuations and a grand total that updates automatically.',
      bulletPoints: [
        'Tap any platform card to open that collection',
        'Pull to refresh to update all prices at once'
      ],
      icon: const FaIcon(FontAwesomeIcons.chartLine, size: 48, color: Colors.amber),
      preview: const MockSnapshotCard(),
    ),
    OnboardingContent(
      title: 'FEATURE 02',
      subtitle: 'Add games in seconds',
      description: 'Search by title or scan a barcode. Valora fetches the cover art, metadata and current market price automatically.',
      bulletPoints: [
        'Tap + in any collection to start adding',
        'Set your condition - loose, complete or sealed'
      ],
      icon: const FaIcon(FontAwesomeIcons.barcode, size: 48, color: Colors.amber),
      preview: const MockSearchList(),
    ),
    OnboardingContent(
      title: 'FEATURE 03',
      subtitle: 'Real market prices',
      description: 'Every game shows loose, complete and sealed values from real eBay sales data. Set your condition once and Valora always shows the right price.',
      bulletPoints: [
        'Condition-based pricing (Loose, CIB, Sealed)',
        'Track profit/loss vs your purchase price',
      ],
      icon: const FaIcon(FontAwesomeIcons.tags, size: 48, color: Colors.amber),
      preview: const MockPriceList(),
    ),
    OnboardingContent(
      title: 'FEATURE 04',
      subtitle: 'All your platforms',
      description: 'Whether it\'s PlayStation, Steam, Epic, or Nintendo, Valora organizes your library across all digital and physical platforms.',
      bulletPoints: [
        'Auto-fetch Steam & Epic digital libraries',
        'Custom images for physical disc collections'
      ],
      icon: const FaIcon(FontAwesomeIcons.gamepad, size: 48, color: Colors.amber),
      preview: const MockPlatformList(),
    ),
    OnboardingContent(
      title: 'FEATURE 05',
      subtitle: 'Share your progress',
      description: 'Generate beautiful snapshots of your collection value and share them with the world.',
      bulletPoints: [
        'Export snapshots with one tap',
        'Show off your weekly gains and rare finds'
      ],
      icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 48, color: Colors.amber),
      preview: const MockSharingPreview(),
    ),
  ];

  static List<OnboardingContent> get changelog => [
    OnboardingContent(
      title: 'WHAT\'S NEW',
      subtitle: 'Valora v0.1.0',
      description: 'We\'ve added new features to help you track your collection better.',
      bulletPoints: [
        'Added onboarding walkthrough for new users',
        'Fixed minor bugs in price fetching'
      ],
      icon: const FaIcon(FontAwesomeIcons.rocket, size: 48, color: Colors.amber),
    ),
  ];
}
