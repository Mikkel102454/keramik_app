import 'package:flutter/material.dart';

/// Shared measurements for the studio's content, surfaces and page families.
abstract final class StudioSpacing {
  static const double page = 16;
  static const double gap = 8;
  static const double section = 20;
  static const double radius = 4;
  static const double contentWidth = 1100;
  static const double formWidth = 760;
}

/// Decorative ceramic vessel, drawn locally without an image download.
class StudioBrandMark extends StatelessWidget {
  const StudioBrandMark({super.key, this.size = 56});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * .18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(size * .12),
      ),
      child: CustomPaint(
        painter: _VesselPainter(
          Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    ),
  );
}

class _VesselPainter extends CustomPainter {
  const _VesselPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .045
      ..strokeCap = StrokeCap.round;
    final body = Path()
      ..moveTo(size.width * .15, size.height * .28)
      ..cubicTo(
        size.width * .18,
        size.height * .68,
        size.width * .28,
        size.height * .82,
        size.width * .38,
        size.height * .84,
      )
      ..lineTo(size.width * .62, size.height * .84)
      ..cubicTo(
        size.width * .72,
        size.height * .82,
        size.width * .82,
        size.height * .68,
        size.width * .85,
        size.height * .28,
      );
    canvas.drawPath(body, paint);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * .15,
        size.height * .18,
        size.width * .7,
        size.height * .2,
      ),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * .33, size.height * .91),
      Offset(size.width * .67, size.height * .91),
      paint,
    );
    for (final y in [.49, .63]) {
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .29, size.height * y)
          ..quadraticBezierTo(
            size.width * .5,
            size.height * (y + .08),
            size.width * .71,
            size.height * y,
          ),
        paint..strokeWidth = size.width * .025,
      );
    }
  }

  @override
  bool shouldRepaint(_VesselPainter oldDelegate) => color != oldDelegate.color;
}

/// Centers finite-width content without introducing another scroll view.
class StudioContent extends StatelessWidget {
  const StudioContent({
    super.key,
    required this.child,
    this.maxWidth = StudioSpacing.contentWidth,
  });
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

class StudioSurface extends StatelessWidget {
  const StudioSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(padding: padding, child: child);
}

/// Keeps captions and controls legible over both light and dark photographs.
class StudioMediaOverlay extends StatelessWidget {
  const StudioMediaOverlay({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(8),
  });
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(StudioSpacing.radius),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class StudioPageHeader extends StatelessWidget {
  const StudioPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
        ],
      ),
    );
  }
}

class StudioSectionHeading extends StatelessWidget {
  const StudioSectionHeading({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    ),
  );
}

class StudioEmptyState extends StatelessWidget {
  const StudioEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.scrollable = true,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  /// Disable when an enclosing sliver owns scrolling and intrinsic sizing.
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
    if (!scrollable) return content;
    return LayoutBuilder(
      builder: (context, constraints) => constraints.hasBoundedHeight
          ? SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: content,
              ),
            )
          : content,
    );
  }
}

class StudioFeatureTile extends StatelessWidget {
  const StudioFeatureTile({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Row(
            children: [
              Icon(icon, size: 26, color: theme.colorScheme.onSurface),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
