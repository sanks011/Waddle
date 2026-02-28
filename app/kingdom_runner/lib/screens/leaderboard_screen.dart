import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

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
                ? const Center(child: CircularProgressIndicator())
                : _leaders.isEmpty
                ? const Center(child: Text('No data available'))
                : RefreshIndicator(
                    onRefresh: _loadLeaderboard,
                    child: ListView.builder(
                      itemCount: _leaders.length,
                      itemBuilder: (context, index) {
                        final user = _leaders[index];
                        final rank = index + 1;

                        String value;
                        switch (_selectedType) {
                          case 'distance':
                            value =
                                '${(user.totalDistance / 1000).toStringAsFixed(2)} km';
                            break;
                          case 'streak':
                            value = '${user.activityStreak} days';
                            break;
                          default:
                            value =
                                '${(user.territorySize / 1000000).toStringAsFixed(2)} km²';
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: rank == 1
                                  ? Colors.amber
                                  : rank == 2
                                  ? Colors.grey[400]
                                  : rank == 3
                                  ? Colors.brown[300]
                                  : Colors.blue,
                              child: Text(
                                '#$rank',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            title: Text(
                              user.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            trailing: Text(
                              value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
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
