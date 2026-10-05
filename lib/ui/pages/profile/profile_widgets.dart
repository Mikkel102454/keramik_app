import 'package:clay_dock/ui/widgets/profile_avatar.dart';
import 'package:flutter/material.dart';

/// Profile identity and counts share one compact layout on both profile pages.
class ProfileIdentity extends StatelessWidget {
  const ProfileIdentity({
    super.key,
    required this.username,
    required this.initials,
    required this.colorHex,
    this.imageUrl,
    this.subtitle,
    this.stats = const [],
    this.actions,
  });
  final String username, initials, colorHex;
  final String? imageUrl, subtitle;
  final List<Widget> stats;
  final Widget? actions;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProfileAvatar(
        initials: initials,
        colorHex: colorHex,
        imageUrl: imageUrl,
        radius: 42,
      ),
      const SizedBox(height: 10),
      Text(
        username,
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(
          subtitle!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      if (stats.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 28,
          runSpacing: 12,
          children: stats,
        ),
      ],
      if (actions != null) ...[const SizedBox(height: 14), actions!],
    ],
  );
}

class ProfileStat extends StatelessWidget {
  const ProfileStat({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });
  final String value, label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
    return onTap == null ? content : InkWell(onTap: onTap, child: content);
  }
}
