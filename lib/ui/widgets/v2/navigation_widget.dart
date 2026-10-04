import 'package:auto_route/auto_route.dart';
import 'package:ceramic_app/config/router/app_router.dart';
import 'package:ceramic_app/ui/widgets/v2/navigation_badge_controller.dart';
import 'package:ceramic_app/l10n/l10n_extensions.dart';
import 'package:flutter/material.dart';

enum NavigationPage { home, materials, discover, notifications, profile }

/// Root destinations share one adaptive shell while retaining the current router.
class StudioScaffold extends StatelessWidget {
  const StudioScaffold({
    super.key,
    required this.currentPage,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });
  final NavigationPage currentPage;
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final expanded = constraints.maxWidth >= 840;
      return Scaffold(
        appBar: appBar,
        body: expanded
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 220,
                    child: NavigationWidget(
                      currentPage: currentPage,
                      vertical: true,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body ?? const SizedBox.shrink()),
                ],
              )
            : body,
        bottomNavigationBar: expanded
            ? null
            : NavigationWidget(currentPage: currentPage),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      );
    },
  );
}

class NavigationWidget extends StatefulWidget {
  const NavigationWidget({
    super.key,
    required this.currentPage,
    this.vertical = false,
  });
  final NavigationPage currentPage;
  final bool vertical;

  @override
  State<NavigationWidget> createState() => _NavigationWidgetState();
}

class _NavigationWidgetState extends State<NavigationWidget> {
  final _selectedItemKey = GlobalKey();
  @override
  void initState() {
    super.initState();
    NavigationBadgeController.instance.refresh();
  }

  void _navigate(NavigationPage page) {
    if (page == widget.currentPage) return;
    final route = switch (page) {
      NavigationPage.home => const HomeRoute(),
      NavigationPage.materials => const MaterialsRoute(),
      NavigationPage.discover => const ShopRoute(),
      NavigationPage.notifications => const NotificationRoute(),
      NavigationPage.profile => const ProfileRoute(),
    };
    context.router.replace(route, onFailure: (_) {});
  }

  @override
  Widget build(BuildContext context) {
    final labels = [
      context.l10n.navigationHome,
      context.l10n.navigationMaterials,
      context.l10n.navigationDiscover,
      context.l10n.navigationChats,
      context.l10n.navigationProfile,
    ];
    const icons = [
      Icons.home_outlined,
      Icons.palette_outlined,
      Icons.explore_outlined,
      Icons.chat_bubble_outline_rounded,
      Icons.person_outline_rounded,
    ];
    const selectedIcons = [
      Icons.home_rounded,
      Icons.palette_rounded,
      Icons.explore_rounded,
      Icons.chat_bubble_rounded,
      Icons.person_rounded,
    ];
    List<Widget> items({bool allLabels = true}) => [
      for (final page in NavigationPage.values)
        _NavigationItem(
          key: widget.currentPage == page ? _selectedItemKey : null,
          label: labels[page.index],
          icon: icons[page.index],
          selectedIcon: selectedIcons[page.index],
          isSelected: widget.currentPage == page,
          vertical: widget.vertical,
          onTap: () => _navigate(page),
          badge: page == NavigationPage.notifications,
          showLabel: allLabels || widget.currentPage == page,
        ),
    ];
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: widget.vertical
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(children: items()),
              )
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final widths = labels.map((label) {
                      final painter = TextPainter(
                        text: TextSpan(
                          text: label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                        maxLines: 1,
                      )..layout();
                      final width = painter.width.ceilToDouble() + 12;
                      painter.dispose();
                      return width < 64 ? 64.0 : width;
                    }).toList();
                    if (widths.every(
                      (width) => width <= constraints.maxWidth / labels.length,
                    )) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in items()) Expanded(child: item),
                        ],
                      );
                    }
                    final selectedWidth = widths[widget.currentPage.index];
                    if (selectedWidth + 48 * (labels.length - 1) <=
                        constraints.maxWidth) {
                      final compactItems = items(allLabels: false);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final page in NavigationPage.values)
                            if (page == widget.currentPage)
                              Expanded(child: compactItems[page.index])
                            else
                              SizedBox(
                                width: 48,
                                child: compactItems[page.index],
                              ),
                        ],
                      );
                    }
                    // Extremely narrow or enlarged layouts retain whole labels.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      final selectedContext = _selectedItemKey.currentContext;
                      if (selectedContext != null && selectedContext.mounted) {
                        Scrollable.ensureVisible(
                          selectedContext,
                          alignment: .5,
                        );
                      }
                    });
                    final scrollingItems = items();
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final page in NavigationPage.values)
                            SizedBox(
                              width: widths[page.index],
                              child: scrollingItems[page.index],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    super.key,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
    required this.vertical,
    required this.badge,
    this.showLabel = true,
  });
  final String label;
  final IconData icon, selectedIcon;
  final bool isSelected, vertical, badge;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget symbol = Icon(
      isSelected ? selectedIcon : icon,
      size: 28,
      color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
    );
    if (badge) {
      symbol = ValueListenableBuilder<int>(
        valueListenable: NavigationBadgeController.instance.count,
        child: symbol,
        builder: (context, count, child) => Badge(
          isLabelVisible: count > 0,
          backgroundColor: colors.error,
          textColor: colors.onError,
          label: Text(count > 99 ? '99+' : '$count'),
          child: child,
        ),
      );
    }
    final title = Text(
      label,
      textAlign: vertical ? TextAlign.start : TextAlign.center,
      maxLines: vertical ? null : 1,
      softWrap: vertical,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
      ),
    );
    return Semantics(
      button: true,
      selected: isSelected,
      label: showLabel ? null : label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Padding(
          padding: vertical
              ? const EdgeInsets.only(bottom: 8)
              : EdgeInsets.zero,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 4 : 0,
                  vertical: 6,
                ),
                child: vertical
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? colors.secondaryContainer : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            symbol,
                            const SizedBox(width: 16),
                            Expanded(child: title),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          symbol,
                          if (showLabel) ...[const SizedBox(height: 3), title],
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
