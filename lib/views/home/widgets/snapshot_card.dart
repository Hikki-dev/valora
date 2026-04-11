import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/home_controller.dart';
import '../../../core/currency_provider.dart';

class SnapshotCard extends ConsumerWidget {
  const SnapshotCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch<HomeState>(homeControllerProvider);
    final currency = ref.watch(currencyProvider);
    
    return Container(
      width: 400,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VALORA',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'TOTAL COLLECTION VALUE',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currency.format(state.totalValuation),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 48),
          _buildPlatformRow('PlayStation', state.platformStats['playstation']?.count ?? 0, Colors.blueAccent),
          const SizedBox(height: 12),
          _buildPlatformRow('Steam', state.platformStats['steam']?.count ?? 0, Colors.white70),
          const SizedBox(height: 12),
          _buildPlatformRow('Nintendo', state.platformStats['nintendo']?.count ?? 0, Colors.redAccent),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('GAMES', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('${state.totalGames}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              const Icon(Icons.qr_code, color: Colors.cyanAccent, size: 40),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text('$count items', style: const TextStyle(color: Colors.white38)),
      ],
    );
  }
}
