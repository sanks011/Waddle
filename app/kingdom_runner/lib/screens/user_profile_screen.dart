import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/territory.dart';
import '../services/api_service.dart';
import '../utils/format_utils.dart';
import '../providers/theme_provider.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/glass_card.dart';

class UserProfileScreen extends StatefulWidget {
  final User user;
  final int rank;

  const UserProfileScreen({super.key, required this.user, required this.rank});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<Territory> _territories = [];
  bool _isLoadingTerritories = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadUserTerritories();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserTerritories() async {
    try {
      final territories = await _apiService.getUserTerritories(widget.user.id);
      if (mounted) {
        setState(() {
          _territories = territories;
          _isLoadingTerritories = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTerritories = false);
      }
    }
  }

  String _getRankLabel(int rank) {
    if (rank == 1) return '🥇 1st Place';
    if (rank == 2) return '🥈 2nd Place';
    if (rank == 3) return '🥉 3rd Place';
    return '#$rank';
  }

  Color _getRankColor(BuildContext context, int rank) {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Theme.of(context).colorScheme.primary;
  }

  String _timeSince(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    return '${(months / 12).floor()}y ago';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final user = widget.user;
    final rankColor = _getRankColor(context, widget.rank);

    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final textSecondary = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    final cardBg = Theme.of(context).colorScheme.surface.withOpacity(0.85);
    final cardBorder = Theme.of(context).dividerColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: FadeTransition(
                opacity: _fadeAnim,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Themed background gradient for the header area
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            rankColor.withOpacity(0.18),
                            Theme.of(context).scaffoldBackgroundColor,
                          ],
                        ),
                      ),
                    ),
                    // Rank badge glow
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rankColor.withOpacity(0.12),
                        ),
                      ),
                    ),
                    // Profile content
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: rankColor.withOpacity(0.2),
                              border: Border.all(color: rankColor, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: rankColor.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: user.avatarPath != null
                                ? ClipOval(
                                    child: Image.asset(
                                      user.avatarPath!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      user.username.isNotEmpty
                                          ? user.username[0].toUpperCase()
                                          : '?',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: rankColor,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            user.username,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: rankColor.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: rankColor.withOpacity(0.4),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _getRankLabel(widget.rank),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: rankColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Body
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Stats Grid ──
                    _sectionHeader(
                      'Stats',
                      Icons.bar_chart_rounded,
                      textPrimary,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _statCard(
                          icon: Icons.terrain_rounded,
                          iconColor: rankColor,
                          label: 'Territory',
                          value: formatArea(user.territorySize),
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _statCard(
                          icon: Icons.directions_run_rounded,
                          iconColor: Theme.of(context).colorScheme.primary,
                          label: 'Distance',
                          value: formatDistance(user.totalDistance),
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _statCard(
                          icon: Icons.local_fire_department_rounded,
                          iconColor: const Color(0xFFFF6B35),
                          label: 'Streak',
                          value: '${user.activityStreak} days',
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        _statCard(
                          icon: Icons.flag_rounded,
                          iconColor: Theme.of(context).colorScheme.primary.withOpacity(0.75),
                          label: 'Territories',
                          value: _isLoadingTerritories
                              ? '...'
                              : '${_territories.length}',
                          cardBg: cardBg,
                          cardBorder: cardBorder,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Activity Info ──
                    _sectionHeader(
                      'Activity',
                      Icons.history_rounded,
                      textPrimary,
                    ),
                    const SizedBox(height: 12),
                    _infoCard(
                      isDarkMode: isDarkMode,
                      cardBg: cardBg,
                      cardBorder: cardBorder,
                      children: [
                        _infoRow(
                          Icons.access_time_rounded,
                          Theme.of(context).colorScheme.primary,
                          'Last Active',
                          _timeSince(user.lastActivity),
                          textPrimary,
                          textSecondary,
                        ),
                        _divider(isDarkMode),
                        _infoRow(
                          Icons.calendar_today_rounded,
                          Theme.of(context).colorScheme.primary,
                          'Member Since',
                          _formatDate(user.createdAt),
                          textPrimary,
                          textSecondary,
                        ),
                        _divider(isDarkMode),
                        _infoRow(
                          Icons.emoji_events_rounded,
                          rankColor,
                          'Global Rank',
                          _getRankLabel(widget.rank),
                          textPrimary,
                          textSecondary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Territories ──
                    _sectionHeader(
                      'Territories',
                      Icons.map_rounded,
                      textPrimary,
                    ),
                    const SizedBox(height: 12),
                    _isLoadingTerritories
                        ? Column(
                            children: List.generate(
                              3,
                              (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ShimmerLoading(
                                  width: double.infinity,
                                  height: 64,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          )
                        : _territories.isEmpty
                        ? _emptyState(
                            Icons.map_outlined,
                            'No territories yet',
                            textSecondary,
                          )
                        : Column(
                            children: _territories
                                .asMap()
                                .entries
                                .map(
                                  (e) => _territoryItem(
                                    e.value,
                                    e.key + 1,
                                    isDarkMode,
                                    cardBg,
                                    cardBorder,
                                    textPrimary,
                                    textSecondary,
                                  ),
                                )
                                .toList(),
                          ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 18, color: textColor.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color cardBg,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required bool isDarkMode,
    required Color cardBg,
    required Color cardBorder,
    required List<Widget> children,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    IconData icon,
    Color iconColor,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Text(label, style: TextStyle(fontSize: 14, color: textSecondary)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDarkMode) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDarkMode
          ? Colors.white.withOpacity(0.07)
          : Colors.black.withOpacity(0.07),
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _territoryItem(
    Territory territory,
    int index,
    bool isDarkMode,
    Color cardBg,
    Color cardBorder,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Territory #$index',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatArea(territory.area),
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.terrain_rounded,
              color: Colors.green.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String message, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: color, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
