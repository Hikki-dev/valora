import 'package:flutter/material.dart';
import '../core/tokens.dart';
import 'comic.dart';

/// Two-option segmented control (theme, currency).
class VSegmented extends StatelessWidget {
  const VSegmented({
    super.key,
    required this.options,
    required this.index,
    required this.onChanged,
    this.semanticLabel,
    this.height = 40,
  });

  final List<String> options;
  final int index;
  final ValueChanged<int> onChanged;
  final String? semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Semantics(
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border.all(color: t.line, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < options.length; i++)
              Semantics(
                button: true,
                selected: i == index,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: height - 4,
                    constraints: const BoxConstraints(minWidth: 44),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: Alignment.center,
                    color: i == index ? t.text : Colors.transparent,
                    child: Text(options[i],
                        style: VText.body(13, i == index ? t.bg : t.text,
                            weight: FontWeight.w900)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.icon, this.label);
  final IconData icon;
  final String label;
}

const _items = [
  _NavSpec(Icons.home_rounded, 'Home'),
  _NavSpec(Icons.collections_bookmark_outlined, 'Library'),
  _NavSpec(Icons.favorite_border_rounded, 'Wishlist'),
  _NavSpec(Icons.settings_outlined, 'Settings'),
];

/// Phone navigation: 4 labelled tabs, active tab gets an accent bar on top.
class VBottomNav extends StatelessWidget {
  const VBottomNav({
    super.key,
    required this.index,
    required this.onTap,
    this.dealCount = 0,
  });

  final int index;
  final ValueChanged<int> onTap;
  final int dealCount;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(top: BorderSide(color: t.line, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    label: _items[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onTap(i),
                      child: Stack(
                        alignment: Alignment.topCenter,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOut,
                            width: i == index ? 44 : 0,
                            height: 4,
                            color: t.accent,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Badge(
                                  isLabelVisible: i == 2 && dealCount > 0,
                                  label: Text('$dealCount'),
                                  backgroundColor: t.accent,
                                  textColor: t.onAccent,
                                  child: Icon(_items[i].icon,
                                      size: 24,
                                      color: i == index ? t.text : t.muted),
                                ),
                                const SizedBox(height: 3),
                                Text(_items[i].label,
                                    style: VText.body(
                                        11, i == index ? t.text : t.muted,
                                        weight: FontWeight.w900)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Desktop navigation: 248px sidebar with a primary "Add game" action.
class VSidebar extends StatelessWidget {
  const VSidebar({
    super.key,
    required this.index,
    required this.onNav,
    required this.onAddGame,
    required this.onInsights,
    required this.isDark,
    required this.onTheme,
    required this.isLkr,
    required this.onCurrency,
    required this.onSignOut,
    this.dealCount = 0,
  });

  final int index;
  final ValueChanged<int> onNav;
  final VoidCallback onAddGame;
  final VoidCallback onInsights;
  final bool isDark;
  final ValueChanged<bool> onTheme;
  final bool isLkr;
  final ValueChanged<bool> onCurrency;
  final VoidCallback onSignOut;
  final int dealCount;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      width: 248,
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.line, width: 2)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
            child:
                Text('VALORA', style: VText.display(22, t.text, spacing: 2.2)),
          ),
          PressableBox(
            color: t.money,
            shadowColor: t.shadow,
            onTap: onAddGame,
            semanticLabel: 'Add game',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_rounded, color: t.onMoney, size: 20),
                const SizedBox(width: 8),
                Text('Add game',
                    style: VText.body(15, t.onMoney, weight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < _items.length; i++)
            _SideItem(
              spec: _items[i],
              selected: i == index,
              badge: i == 2 ? dealCount : 0,
              onTap: () => onNav(i),
            ),
          _SideItem(
            spec: const _NavSpec(Icons.bar_chart_rounded, 'Insights'),
            selected: false,
            onTap: onInsights,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Theme',
                  style: VText.body(13, t.text, weight: FontWeight.w900)),
              VSegmented(
                semanticLabel: 'Theme',
                options: const ['Light', 'Dark'],
                index: isDark ? 1 : 0,
                onChanged: (i) => onTheme(i == 1),
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Currency',
                  style: VText.body(13, t.text, weight: FontWeight.w900)),
              VSegmented(
                semanticLabel: 'Currency',
                options: const ['USD', 'LKR'],
                index: isLkr ? 1 : 0,
                onChanged: (i) => onCurrency(i == 1),
                height: 36,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(height: 2, color: t.soft),
          const SizedBox(height: 6),
          _SideItem(
            spec: const _NavSpec(Icons.logout_rounded, 'Sign out'),
            selected: false,
            danger: true,
            onTap: onSignOut,
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatefulWidget {
  const _SideItem({
    required this.spec,
    required this.selected,
    required this.onTap,
    this.badge = 0,
    this.danger = false,
  });

  final _NavSpec spec;
  final bool selected;
  final VoidCallback onTap;
  final int badge;
  final bool danger;

  @override
  State<_SideItem> createState() => _SideItemState();
}

class _SideItemState extends State<_SideItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    final fg = widget.selected
        ? t.bg
        : widget.danger
            ? t.danger
            : (_hover ? t.text : t.muted);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.spec.label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: widget.selected ? t.text : Colors.transparent,
                border: Border.all(
                    color: widget.selected
                        ? t.text
                        : (_hover ? t.soft : Colors.transparent),
                    width: 2),
              ),
              child: Row(
                children: [
                  Icon(widget.spec.icon, size: 20, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.spec.label,
                        style: VText.body(15, fg, weight: FontWeight.w900)),
                  ),
                  if (widget.badge > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: t.accent,
                        border: Border.all(color: t.line, width: 2),
                      ),
                      child: Text('${widget.badge}',
                          style: VText.body(12, t.onAccent,
                              weight: FontWeight.w900)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Tablet navigation rail (600-999px).
class VRail extends StatelessWidget {
  const VRail({
    super.key,
    required this.index,
    required this.onNav,
    required this.onAddGame,
    required this.isDark,
    required this.onTheme,
    required this.onSignOut,
    this.dealCount = 0,
  });

  final int index;
  final ValueChanged<int> onNav;
  final VoidCallback onAddGame;
  final bool isDark;
  final VoidCallback onTheme;
  final VoidCallback onSignOut;
  final int dealCount;

  @override
  Widget build(BuildContext context) {
    final t = VTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        border: Border(right: BorderSide(color: t.line, width: 2)),
      ),
      child: NavigationRail(
        backgroundColor: Colors.transparent,
        selectedIndex: index,
        onDestinationSelected: onNav,
        labelType: NavigationRailLabelType.all,
        indicatorColor: t.money,
        indicatorShape: const RoundedRectangleBorder(),
        selectedIconTheme: IconThemeData(color: t.onMoney),
        unselectedIconTheme: IconThemeData(color: t.muted),
        selectedLabelTextStyle: VText.body(11, t.text, weight: FontWeight.w900),
        unselectedLabelTextStyle:
            VText.body(11, t.muted, weight: FontWeight.w900),
        leading: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: PressableBox(
            color: t.money,
            shadowColor: t.shadow,
            padding: EdgeInsets.zero,
            minHeight: 48,
            onTap: onAddGame,
            semanticLabel: 'Add game',
            child: SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.add_rounded, color: t.onMoney)),
          ),
        ),
        trailing: Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Switch theme',
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode,
                    size: 22, color: t.muted),
                onPressed: onTheme,
              ),
              IconButton(
                tooltip: 'Sign out',
                icon: Icon(Icons.logout_rounded, size: 22, color: t.danger),
                onPressed: onSignOut,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        destinations: [
          for (var i = 0; i < _items.length; i++)
            NavigationRailDestination(
              icon: Badge(
                isLabelVisible: i == 2 && dealCount > 0,
                label: Text('$dealCount'),
                child: Icon(_items[i].icon),
              ),
              label: Text(_items[i].label),
            ),
        ],
      ),
    );
  }
}
