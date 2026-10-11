import 'package:flutter/material.dart';
import 'package:real_liquid_glass/real_liquid_glass.dart';

import 'liquid_glass_layout.dart';

class MainBottomNavigationBar extends StatelessWidget {
  const MainBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.miniPlayer = const SizedBox.shrink(),
    this.liquidGlass = false,
    this.fallbackGlassTransparency = 0.4,
    this.showUpdateBadge = false,
    this.onLayoutExtentChanged,
  });

  static const double navigationBarHeight = 58;

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget miniPlayer;
  final bool liquidGlass;
  final double fallbackGlassTransparency;
  final bool showUpdateBadge;
  final ValueChanged<double>? onLayoutExtentChanged;

  @override
  Widget build(BuildContext context) {
    if (liquidGlass) {
      return _LiquidGlassBottomNavigation(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
        miniPlayer: miniPlayer,
        fallbackGlassTransparency: fallbackGlassTransparency,
        showUpdateBadge: showUpdateBadge,
        onLayoutExtentChanged: onLayoutExtentChanged,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        miniPlayer,
        NavigationBar(
          height: navigationBarHeight,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          destinations: destinations,
        ),
      ],
    );
  }
}

class _LiquidGlassBottomNavigation extends StatelessWidget {
  const _LiquidGlassBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.miniPlayer,
    required this.fallbackGlassTransparency,
    required this.showUpdateBadge,
    required this.onLayoutExtentChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final Widget miniPlayer;
  final double fallbackGlassTransparency;
  final bool showUpdateBadge;
  final ValueChanged<double>? onLayoutExtentChanged;

  IconData _iconOf(Widget widget) {
    if (widget is Icon) return widget.icon ?? Icons.circle_outlined;
    if (widget is Badge && widget.child != null) return _iconOf(widget.child!);
    return Icons.circle_outlined;
  }

  String _symbolOf(IconData icon) => switch (icon) {
    Icons.home_outlined => 'house',
    Icons.home => 'house.fill',
    Icons.favorite_border => 'heart',
    Icons.favorite => 'heart.fill',
    Icons.settings_outlined => 'gearshape',
    Icons.settings => 'gearshape.fill',
    Icons.search_outlined || Icons.search => 'magnifyingglass',
    _ => 'circle',
  };

  List<LiquidGlassBarItem> _itemsForDestinations() {
    return [
      for (final destination in destinations)
        LiquidGlassBarItem(
          icon: _iconOf(destination.icon),
          selectedIcon: _iconOf(destination.selectedIcon ?? destination.icon),
          sfSymbol: _symbolOf(_iconOf(destination.icon)),
          selectedSfSymbol: _symbolOf(
            _iconOf(destination.selectedIcon ?? destination.icon),
          ),
          label: destination.label,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final navigationBarHeight = LiquidGlassLayout.navigationBarHeight(context);
    return LiquidGlassDockExtentReporter(
      onChanged: onLayoutExtentChanged ?? (_) {},
      child: Padding(
        padding: EdgeInsets.only(
          bottom: LiquidGlassLayout.dockBottomInset(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: Alignment.bottomCenter,
              child: miniPlayer,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LiquidGlassLayout.horizontalPadding,
                LiquidGlassLayout.verticalPadding,
                LiquidGlassLayout.horizontalPadding,
                LiquidGlassLayout.navigationBarBottomPadding,
              ),
              child: SizedBox(
                height: navigationBarHeight,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final expansion = LiquidGlassLayout.nativeTabBarExpansion(
                      context,
                    );
                    final barWidth = constraints.maxWidth + expansion * 2;
                    final bar = ClipRRect(
                      borderRadius: BorderRadius.circular(
                        navigationBarHeight / 2,
                      ),
                      child: SizedBox(
                        width: barWidth,
                        child: LiquidGlassBottomBar(
                          items: _itemsForDestinations(),
                          currentIndex: selectedIndex,
                          onTap: onDestinationSelected,
                          height: navigationBarHeight,
                          showLabels: true,
                          tint: Theme.of(context).colorScheme.primary,
                          fallbackIntensity: fallbackGlassTransparency,
                        ),
                      ),
                    );

                    final expandedBar = expansion == 0
                        ? bar
                        : OverflowBox(
                            minWidth: barWidth,
                            maxWidth: barWidth,
                            minHeight: navigationBarHeight,
                            maxHeight: navigationBarHeight,
                            alignment: Alignment.center,
                            child: bar,
                          );

                    if (!showUpdateBadge || destinations.isEmpty) {
                      return expandedBar;
                    }

                    final itemWidth = barWidth / destinations.length;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        expandedBar,
                        Positioned(
                          top: 10,
                          left: itemWidth * (destinations.length - 0.5) - 4,
                          child: IgnorePointer(
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
