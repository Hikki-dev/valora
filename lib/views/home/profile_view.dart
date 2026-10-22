import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/home_controller.dart';
import '../../core/currency_provider.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/comic.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VTokens.of(context);
    final user = Supabase.instance.client.auth.currentUser;
    final total =
        ref.watch(homeControllerProvider.select((s) => s.totalValuation));
    final count = ref.watch(homeControllerProvider.select((s) => s.totalGames));
    final hide = ref.watch(homeControllerProvider.select((s) => s.hidePricing));
    final currency = ref.watch(currencyProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;
    final pad = isDesktop ? 40.0 : 16.0;
    final email = user?.email ?? 'Valora collector';

    return Scaffold(
      backgroundColor: t.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: EdgeInsets.fromLTRB(pad, isDesktop ? 32 : 16, pad, 40),
              children: [
                Text('YOU', style: VText.label(12, t.muted)),
                const SizedBox(height: 4),
                Text('Profile',
                    style: VText.display(isDesktop ? 36 : 28, t.text)),
                const SizedBox(height: 18),
                HardBox(
                  shadowOffset: 4,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: t.money,
                            border: Border.all(color: t.line, width: 2)),
                        child: Text(email.characters.first.toUpperCase(),
                            style: VText.display(24, t.onMoney)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: VText.body(16, t.text,
                                    weight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                                hide
                                    ? '$count games · value hidden'
                                    : '$count games · ${currency.format(total)}',
                                style: VText.body(13, t.muted,
                                    weight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const _Section('APPEARANCE'),
                HardBox(
                  shadowOffset: 0,
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    _SettingRow(
                      label: 'Theme',
                      hint:
                          'Light is easier outdoors, dark is easier at night.',
                      control: VSegmented(
                        semanticLabel: 'Theme',
                        options: const ['Light', 'Dark'],
                        index: isDark ? 1 : 0,
                        onChanged: (i) {
                          if ((i == 1) != isDark) {
                            ref.read(themeProvider.notifier).toggle();
                          }
                        },
                      ),
                    ),
                    Divider(color: t.soft, thickness: 2, height: 24),
                    _SettingRow(
                      label: 'Currency',
                      hint: 'Prices are fetched in USD and converted.',
                      control: VSegmented(
                        semanticLabel: 'Currency',
                        options: const ['USD', 'LKR'],
                        index: currency.currency == AppCurrency.lkr ? 1 : 0,
                        onChanged: (i) {
                          if ((i == 1) !=
                              (currency.currency == AppCurrency.lkr)) {
                            ref
                                .read(currencyProvider.notifier)
                                .toggleCurrency();
                          }
                        },
                      ),
                    ),
                    Divider(color: t.soft, thickness: 2, height: 24),
                    _SettingRow(
                      label: 'Hide values',
                      hint:
                          'Masks prices on Home, handy when sharing your screen.',
                      control: Switch(
                        value: hide,
                        activeThumbColor: t.onMoney,
                        activeTrackColor: t.money,
                        onChanged: (_) => ref
                            .read(homeControllerProvider.notifier)
                            .togglePricingVisibility(),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 28),
                const _Section('HOW PRICES WORK'),
                HardBox(
                  color: t.surface2,
                  shadowOffset: 0,
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Physical games use real sold-listing prices for the condition you own: '
                    'game only, complete, or sealed. Digital games use the current store price. '
                    'If no price exists, Valora shows a dash. It never makes one up. '
                    'Prices refresh at most every 24 hours (6 for digital).',
                    style: VText.body(13, t.text, weight: FontWeight.w500)
                        .copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 28),
                const _Section('ACCOUNT'),
                HardBox(
                  shadowOffset: 0,
                  padding: const EdgeInsets.all(14),
                  child: Column(children: [
                    _Info('Email', email),
                    Divider(color: t.soft, thickness: 2, height: 20),
                    _Info('Joined', _date(user?.createdAt)),
                    Divider(color: t.soft, thickness: 2, height: 20),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (_, s) => _Info(
                          'Version', s.hasData ? 'v${s.data!.version}' : '…'),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                PressableBox(
                  onTap: () =>
                      ref.read(authControllerProvider.notifier).signOut(),
                  color: Colors.transparent,
                  shadowOffset: 0,
                  semanticLabel: 'Sign out',
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.logout_rounded, size: 18, color: t.danger),
                    const SizedBox(width: 8),
                    Text('Sign out',
                        style:
                            VText.body(14, t.danger, weight: FontWeight.w900)),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _date(String? s) {
    final d = s == null ? null : DateTime.tryParse(s);
    if (d == null) return 'Unknown';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title, style: VText.label(12, VTokens.of(context).muted)),
      );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(
      {required this.label, required this.hint, required this.control});
  final String label, hint;
  final Widget control;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: VText.body(14, t.text, weight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(hint,
                  style: VText.body(12, t.muted, weight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        control,
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Row(
      children: [
        Text(label, style: VText.body(14, t.muted, weight: FontWeight.w700)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: VText.body(14, t.text, weight: FontWeight.w900)),
        ),
      ],
    );
  }
}
