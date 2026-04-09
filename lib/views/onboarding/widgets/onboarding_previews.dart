import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MockSnapshotCard extends StatelessWidget {
  const MockSnapshotCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'VALORA',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'TOTAL COLLECTION VALUE',
            style: TextStyle(
              color: Colors.white38,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '\$1,847.00',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
          _buildRow('PlayStation Discs', '\$682', Colors.blueAccent),
          const SizedBox(height: 10),
          _buildRow('Steam Library', '\$743', Colors.white70),
          const SizedBox(height: 10),
          _buildRow('Nintendo', '\$224', Colors.redAccent),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        const Spacer(),
        Text(value, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }
}

class MockSearchList extends StatelessWidget {
  const MockSearchList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, color: Colors.amber, size: 18),
                SizedBox(width: 12),
                Text('God of War Ragnarök...', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildResult('God of War Ragnarök', '\$42.00', 'PS5 Disc', Colors.blueAccent),
          const SizedBox(height: 12),
          _buildResult('Spider-Man 2', '\$55.00', 'PS5 Disc', Colors.redAccent),
          const SizedBox(height: 12),
           Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Row(
              children: [
                Icon(Icons.barcode_reader, color: Colors.amber, size: 18),
                SizedBox(width: 12),
                Text('Or scan barcode...', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(String title, String price, String platform, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.videogame_asset, color: Colors.white24, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('$price • $platform', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
            child: const Text('+ Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class MockPriceList extends StatelessWidget {
  const MockPriceList({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPriceRow('Loose', 'Disc only', '\$32.00', false),
          const SizedBox(height: 12),
          _buildPriceRow('Complete', 'Disc + case + manual', '\$42.00', true),
          const SizedBox(height: 12),
          _buildPriceRow('New & sealed', 'Factory sealed', '\$68.00', false),
          const SizedBox(height: 24),
          const Text('Your copy is worth', style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          const Text('\$42.00', style: TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String sub, String price, bool highlight) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05), width: highlight ? 2 : 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(sub, style: const TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 16)),
              if (highlight) const Text('Your copy', style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}

class MockPlatformList extends StatelessWidget {
  const MockPlatformList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildItem('Playstation Discs', '12 games', '\$682', const Color(0xFF0D47A1), Icons.videogame_asset),
        const SizedBox(height: 12),
        _buildItem('Steam', '45 games', '\$743', const Color(0xFF171A21), Icons.laptop),
        const SizedBox(height: 12),
        _buildItem('Nintendo', '8 games', '\$224', const Color(0xFFE60012), Icons.videogame_asset),
      ],
    );
  }

  Widget _buildItem(String title, String count, String value, Color bg, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text(count, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}

class MockSharingPreview extends StatelessWidget {
  const MockSharingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
           width: 280,
           padding: const EdgeInsets.all(24),
           decoration: BoxDecoration(
             color: const Color(0xFF0A0A0F),
             borderRadius: BorderRadius.circular(32),
             border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
           ),
           child: const Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text('VALORA', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, letterSpacing: 8, fontSize: 14)),
               SizedBox(height: 20),
               Text('\$1,847.00', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -2)),
               SizedBox(height: 20),
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text('GAMES', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                       Text('65', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                     ],
                   ),
                   Icon(Icons.qr_code_2, color: Colors.cyanAccent, size: 32),
                 ],
               ),
             ],
           ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share, color: Colors.black, size: 18),
              SizedBox(width: 12),
              Text('Share Snapshot', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(duration: 2.seconds, color: Colors.white54),
      ],
    );
  }
}

class MockSyncPreview extends StatelessWidget {
  const MockSyncPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text('LIBRARY SYNC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 13)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: const Text('SECURE', style: TextStyle(color: Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSourceRow('Steam Library', '45 games found', true, 0.8),
          const SizedBox(height: 16),
          _buildSourceRow('PlayStation Network', 'Ready to sync', false, 0.0),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('IMPORT ALL GAMES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceRow(String title, String status, bool active, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(status, style: TextStyle(color: active ? Colors.amber : Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: active ? progress : 0,
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            valueColor: AlwaysStoppedAnimation<Color>(active ? Colors.amber : Colors.white10),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
