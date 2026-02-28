import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/territory_provider.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final territoryProvider = Provider.of<TerritoryProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final userTerritories = territoryProvider.getTerritoriesByUser(user.id);
    final totalArea = territoryProvider.getTotalAreaByUser(user.id);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _buildStatRow(
                      'Total Distance',
                      '${(user.totalDistance / 1000).toStringAsFixed(2)} km',
                      Icons.directions_run,
                    ),
                    _buildStatRow(
                      'Kingdom Size',
                      '${(totalArea / 1000000).toStringAsFixed(2)} km²',
                      Icons.terrain,
                    ),
                    _buildStatRow(
                      'Territories',
                      '${userTerritories.length}',
                      Icons.map,
                    ),
                    _buildStatRow(
                      'Activity Streak',
                      '${user.activityStreak} days',
                      Icons.local_fire_department,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Rules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const ListTile(
                      leading: Icon(Icons.info_outline),
                      title: Text(
                        'Complete at least one walk/run every 3 days',
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const ListTile(
                      leading: Icon(Icons.warning_outlined),
                      title: Text('Inactive territories will be lost'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const ListTile(
                      leading: Icon(Icons.tips_and_updates_outlined),
                      title: Text('Create closed loops to claim territory'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
