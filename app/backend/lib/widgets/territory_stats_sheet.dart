import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../models/territory.dart';
import '../providers/auth_provider.dart';
import '../screens/bomb_placement_screen.dart';
import '../utils/format_utils.dart';
import '../utils/territory_colors.dart';

/// Shows an animated bottom sheet with stats about a tapped [territory].
void showTerritoryStats(
  BuildContext context,
  Territory territory,
  TerritoryWithColor colored, {
  required String currentUserId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TerritoryStatsSheet(
      territory: territory,
      colored: colored,
      isOwner: territory.userId == currentUserId,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

class _TerritoryStatsSheet extends StatefulWidget {
  final Territory territory;
  final TerritoryWithColor colored;
  final bool isOwner;

  const _TerritoryStatsSheet({
    required this.territory,
    required this.colored,
    required this.isOwner,
  });

  @override
  State<_TerritoryStatsSheet> createState() => _TerritoryStatsSheetState();
}

class _TerritoryStatsSheetState extends State<_TerritoryStatsSheet> {
  late int _localBombCount;

  @override
  void initState() {
    super.initState();
    _localBombCount = widget.territory.bombCount;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fill = widget.colored.fillColor;
    final border = widget.colored.borderColor;
    final auth = Provider.of<AuthProvider>(context);
    final bombsInInventory = auth.currentUser?.bombInventory ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A1A2E).withOpacity(0.96)
                  : Colors.white.withOpacity(0.97),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border(
                top: BorderSide(color: fill.withOpacity(0.5), width: 2),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ───────────────────────────────────────
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // ── Header ────────────────────────────────────────────
                Row(
                  children: [
                    // Colour / kingdom badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: fill.withOpacity(0.18),
                        border: Border.all(color: fill, width: 2.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          'assets/castle.svg',
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  "${widget.territory.username}'s Kingdom",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: fill,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: fill.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: fill.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Text(
                                    'Yours',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: fill,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.territory.username,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: fill.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 16),

                // ── Stats grid ────────────────────────────────────────
                Row(
                  children: [
                    _StatTile(
                      icon: Icons.straighten_rounded,
                      label: 'Area',
                      value: formatArea(widget.territory.area),
                      accentColor: fill,
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      icon: Icons.location_on_rounded,
                      label: 'Points',
                      value: '${widget.territory.polygon.length}',
                      accentColor: fill,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Captured',
                      value: _formatDate(widget.territory.createdAt),
                      accentColor: fill,
                    ),
                    const SizedBox(width: 12),
                    _StatTile(
                      icon: Icons.update_rounded,
                      label: 'Last Active',
                      value: _formatDate(widget.territory.lastUpdated),
                      accentColor: fill,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Colour swatch ─────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'Kingdom Colour',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [fill, border]),
                        borderRadius: BorderRadius.circular(7),
                        boxShadow: [
                          BoxShadow(
                            color: fill.withOpacity(0.4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: fill.withOpacity(0.2), thickness: 1),
                const SizedBox(height: 14),

                // ── Bomb section ──────────────────────────────────────
                if (widget.isOwner)
                  _buildOwnerBombSection(context, theme, isDark, fill, bombsInInventory)
                else if (_localBombCount > 0)
                  _buildEnemyBombWarning(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOwnerBombSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    Color fill,
    int bombsInInventory,
  ) {
    final bombColor = const Color(0xFF7B2FBE);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SvgPicture.asset('assets/explosive-bomb.svg', width: 20, height: 20),
            const SizedBox(width: 8),
            Text(
              'Armed Defence',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: bombColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: bombColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: bombColor.withOpacity(0.3)),
              ),
              child: Text(
                '$bombsInInventory in bag',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: bombColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bomb slot indicators
        Row(
          children: List.generate(3, (i) {
            final placed = i < _localBombCount;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: placed
                      ? bombColor.withOpacity(0.18)
                      : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: placed ? bombColor.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: placed
                    ? Center(child: SvgPicture.asset('assets/explosive-bomb.svg', width: 26, height: 26))
                    : Icon(Icons.add, size: 18, color: Colors.grey.withOpacity(0.4)),
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        // Single navigation CTA — opens the full visual placement screen
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Capture navigator BEFORE pop so we can use it after widget is disposed
              final nav = Navigator.of(context);
              nav.pop(); // close the bottom sheet
              nav.push(
                MaterialPageRoute(
                  builder: (_) => BombPlacementScreen(territory: widget.territory),
                ),
              );
            },
            icon: SvgPicture.asset(
              'assets/explosive-bomb.svg',
              width: 18,
              height: 18,
            ),
            label: const Text('Arm Defence — Place Bombs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: bombColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (bombsInInventory == 0) ...[  
          const SizedBox(height: 8),
          Text(
            'No bombs in inventory — visit the Armory to buy some.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnemyBombWarning(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.withOpacity(0.35), width: 1.5),
      ),
      child: Row(
        children: [
          SvgPicture.asset('assets/explosive-bomb.svg', width: 28, height: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ARMED TERRITORY',
                    style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 2),
                Text(
                  'This territory has $_localBombCount bomb${_localBombCount == 1 ? '' : 's'} inside. Entering will trigger them!',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.red.withOpacity(0.8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).round()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).round()}mo ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? accentColor.withOpacity(0.10)
              : accentColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
