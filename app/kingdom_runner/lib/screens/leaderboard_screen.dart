import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../models/user.dart';
import '../services/api_service.dart';
import '../widgets/shimmer_loading.dart';
import '../utils/format_utils.dart';
import '../providers/theme_provider.dart';
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
      appBar: AppBar(title: const Text('Leaderboard')),
      body: Column(
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
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 10,
                                      sigmaY: 10,
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.black.withOpacity(0.15),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    UserProfileScreen(
                                                      user: user,
                                                      rank: rank,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: isDarkMode
                                                        ? Colors.white
                                                              .withOpacity(0.1)
                                                        : Colors.black
                                                              .withOpacity(
                                                                0.08,
                                                              ),
                                                    border: Border.all(
                                                      color: isDarkMode
                                                          ? Colors.white
                                                                .withOpacity(
                                                                  0.3,
                                                                )
                                                          : Colors.black
                                                                .withOpacity(
                                                                  0.2,
                                                                ),
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: Center(
                                                    child: rank <= 3
                                                        ? Icon(
                                                            Icons.star,
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                      .withOpacity(
                                                                        0.8,
                                                                      )
                                                                : Colors.black
                                                                      .withOpacity(
                                                                        0.7,
                                                                      ),
                                                            size: 24,
                                                          )
                                                        : Text(
                                                            '$rank',
                                                            style: TextStyle(
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                        .withOpacity(
                                                                          0.8,
                                                                        )
                                                                  : Colors.black
                                                                        .withOpacity(
                                                                          0.7,
                                                                        ),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                  ),
                                                ),
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
                                                          color: isDarkMode
                                                              ? Colors.white
                                                              : Colors.black87,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            icon,
                                                            size: 16,
                                                            color: isDarkMode
                                                                ? Colors.white
                                                                      .withOpacity(
                                                                        0.6,
                                                                      )
                                                                : Colors.black
                                                                      .withOpacity(
                                                                        0.6,
                                                                      ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            value,
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: isDarkMode
                                                                  ? Colors.white
                                                                        .withOpacity(
                                                                          0.6,
                                                                        )
                                                                  : Colors.black
                                                                        .withOpacity(
                                                                          0.6,
                                                                        ),
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
                                                  color: isDarkMode
                                                      ? Colors.white
                                                            .withOpacity(0.3)
                                                      : Colors.black
                                                            .withOpacity(0.25),
                                                  size: 24,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
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
    );
  }
}
