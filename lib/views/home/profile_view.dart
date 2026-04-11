import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/home_controller.dart';
import '../../core/currency_provider.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final homeState = ref.watch<HomeState>(homeControllerProvider);
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('PROFILE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAvatar(user, context),
            const SizedBox(height: 24),
            Text(
              user?.email ?? 'Valora Collector',
              style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getTier(homeState.totalValuation),
                style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            ),
            const SizedBox(height: 48),
            _buildStatsGrid(context, homeState, currency, textColor),
            const SizedBox(height: 48),
            _buildSectionHeader('ACCOUNT SETTINGS', textColor),
            const SizedBox(height: 16),
            _buildSettingTile(context, Icons.alternate_email, 'Email', user?.email ?? 'Unknown', textColor),
            _buildSettingTile(context, Icons.calendar_today, 'Joined', _formatDate(user?.createdAt), textColor),
            const SizedBox(height: 32),
            _buildSectionHeader('SUPPORT', textColor),
            const SizedBox(height: 16),
            _buildSettingTile(context, Icons.help_outline, 'Help & Feedback', 'Submit a ticket', textColor, isAction: true),
            _buildSettingTile(context, Icons.info_outline, 'About Valora', 'v1.0.0', textColor),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(User? user, BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).primaryColor, width: 3),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.person, size: 60, color: Theme.of(context).primaryColor),
      ),
    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut);
  }

  Widget _buildStatsGrid(BuildContext context, HomeState state, CurrencyState currency, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context, 
            'NET WORTH', 
            currency.format(state.totalValuation), 
            Icons.account_balance_wallet_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            context, 
            'TITLES', 
            state.totalGames.toString(), 
            Icons.videogame_asset_outlined,
          ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColor, size: 24),
          const SizedBox(height: 16),
          Text(
            label,
            style: const TextStyle(color: Colors.white24, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5),
          ),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(color: textColor.withValues(alpha: 0.4), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, IconData icon, String label, String value, Color textColor, {bool isAction = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor.withValues(alpha: 0.4), size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isAction ? Theme.of(context).primaryColor : textColor.withValues(alpha: 0.4), 
              fontSize: 13,
              fontWeight: isAction ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          if (isAction) ...[
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Theme.of(context).primaryColor, size: 16),
          ],
        ],
      ),
    );
  }

  String _getTier(double valuation) {
    if (valuation > 10000) return 'LEGENDARY COLLECTOR';
    if (valuation > 5000) return 'ELITE INVESTOR';
    if (valuation > 1000) return 'PRO HOBBYIST';
    return 'RISING STAR';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Recent';
    }
  }
}
