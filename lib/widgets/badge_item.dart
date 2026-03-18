import 'package:flutter/material.dart';
import 'package:habit_tracker/models/badge_model.dart';

class BadgeItem extends StatelessWidget {
  const BadgeItem({super.key, required this.badge, this.onTap});

  final BadgeModel badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final style = _styleForTier(badge.tier);
    final card = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: <Color>[style.base, style.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: style.accent.withValues(alpha: 0.35),
            blurRadius: badge.isUnlocked ? 16 : 8,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(style.icon, color: Colors.white, size: 24),
                const Spacer(),
                if (!badge.isUnlocked)
                  const Icon(Icons.lock, color: Colors.white, size: 20),
              ],
            ),
            const Spacer(),
            Text(
              badge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${badge.milestoneDays} ngày',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    final visual = badge.isUnlocked
        ? card
        : ColorFiltered(
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0.2126,
              0.7152,
              0.0722,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: Opacity(opacity: 0.72, child: card),
          );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: visual,
    );
  }

  _BadgeVisualStyle _styleForTier(BadgeTier tier) {
    switch (tier) {
      case BadgeTier.bronze:
        return const _BadgeVisualStyle(
          base: Color(0xFF7A4E2D),
          accent: Color(0xFFB56C3E),
          icon: Icons.workspace_premium,
        );
      case BadgeTier.silver:
        return const _BadgeVisualStyle(
          base: Color(0xFF5E6672),
          accent: Color(0xFF97A2B1),
          icon: Icons.shield_moon,
        );
      case BadgeTier.gold:
        return const _BadgeVisualStyle(
          base: Color(0xFF8A6A00),
          accent: Color(0xFFE7B939),
          icon: Icons.emoji_events,
        );
      case BadgeTier.diamond:
        return const _BadgeVisualStyle(
          base: Color(0xFF004C7E),
          accent: Color(0xFF24B3FF),
          icon: Icons.diamond,
        );
    }
  }
}

class _BadgeVisualStyle {
  const _BadgeVisualStyle({
    required this.base,
    required this.accent,
    required this.icon,
  });

  final Color base;
  final Color accent;
  final IconData icon;
}
