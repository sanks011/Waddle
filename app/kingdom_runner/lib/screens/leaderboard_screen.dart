import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/format_utils.dart';
import '../providers/theme_provider.dart';
import '../widgets/glass_card.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  List<User> _leaders = [];
  bool _isLoading = true;
  String _selectedType = 'territory';

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final leaders = await _apiService.getLeaderboard(type: _selectedType);
      setState(() {
        _leaders = leaders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load leaderboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Leaderboard')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'territory',
                  label: Text('Territory'),
                  icon: Icon(Icons.terrain),
                ),
                ButtonSegment(
                  value: 'distance',
                  label: Text('Distance'),
                  icon: Icon(Icons.directions_run),
                ),
                ButtonSegment(
                  value: 'streak',
                  label: Text('Streak'),
                  icon: Icon(Icons.local_fire_department),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                });
                _loadLeaderboard();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ShimmerLoading(
                          width: double.infinity,
                          height: 80,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      );
                    },
                  )
                : _leaders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.leaderboard_outlined,
                          size: 80,
                          color: Colors.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No data available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _leaders.length,
                      itemBuilder: (context, index) {
                        final user = _leaders[index];
                        final rank = index + 1;

                        String value;
                        IconData icon;
                        switch (_selectedType) {
                          case 'distance':
                            value = formatDistance(user.totalDistance);
                            icon = Icons.directions_run;
                            break;
                          case 'streak':
                            value = '${user.activityStreak} days';
                            icon = Icons.local_fire_department;
                            break;
                          default:
                            value = formatArea(user.territorySize);
                            icon = Icons.terrain;
                        }

                          return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          curve: Curves.easeOut,
                          builder: (context, animValue, child) {
                            return Opacity(
                              opacity: animValue,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(16.0),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => UserProfileScreen(
                                          user: user,
                                          rank: rank,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      _buildAvatarWithRank(context, user, rank),
                                      const SizedBox(width: 16),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        user.username,
                                                        style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            icon,
                                                            size: 16,
                                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            value,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                          Icon(
                                            Icons.chevron_right,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                            size: 24,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
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

  // ── Avatar with rank badge ──────────────────────────────────────────────────

  Color _rankColor(BuildContext context, int rank) {
    switch (rank) {
      case 1: return const Color(0xFFFFD700);
      case 2: return const Color(0xFFB0B0B0);
      case 3: return const Color(0xFFCD7F32);
      default: return Theme.of(context).colorScheme.primary;
    }
  }

  Widget _buildAvatarWithRank(BuildContext context, User user, int rank) {
    final rankColor = _rankColor(context, rank);
    final hasAvatar = user.avatarPath != null && user.avatarPath!.isNotEmpty;

    return SizedBox(
      width: 52,
      height: 60, // extra height for the badge that hangs below
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Avatar circle
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border.all(color: rankColor, width: 2),
              image: hasAvatar
                  ? DecorationImage(
                      image: AssetImage(user.avatarPath!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasAvatar
                ? null
                : Center(
                    child: Text(
                      user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
          ),

          // Rank badge pinned to bottom-center of the circle
          Positioned(
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: rankColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1.5,
                ),
              ),
              child: Text(
                '#$rank',
                style: TextStyle(
                  color: rank <= 2 ? Colors.black87 : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
