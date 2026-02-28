import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/territory_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/user.dart';
import '../utils/format_utils.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final authProvider     = Provider.of<AuthProvider>(context, listen: false);
    final territoryProvider = Provider.of<TerritoryProvider>(context, listen: false);

    await Future.wait([
      authProvider.loadCurrentUser(),
      territoryProvider.loadTerritories(),
    ]);

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authProvider      = Provider.of<AuthProvider>(context);
    final territoryProvider = Provider.of<TerritoryProvider>(context);
    final user              = authProvider.currentUser;
    final theme             = Theme.of(context);
    final isDark            = theme.brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not found')));
    }

    final userTerritories = territoryProvider.getTerritoriesByUser(user.id);
    final totalArea       = territoryProvider.getTotalAreaByUser(user.id);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshData,
          ),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileCard(context, user, theme),
              const SizedBox(height: 16),
              _buildStatsCard(context, user, theme, userTerritories.length, totalArea),
              const SizedBox(height: 16),
              _buildSettingsCard(context, theme, isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Profile card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard(BuildContext context, User user, ThemeData theme) {
    return _card(
      theme,
      child: Column(
        children: [
          Hero(
            tag: 'profile_avatar',
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
              child: user.avatarPath != null
                  ? CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage(user.avatarPath!),
                      backgroundColor: theme.dividerColor,
                    )
                  : CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.username,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(user.email, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  // ─── Statistics card ───────────────────────────────────────────────────────

  Widget _buildStatsCard(
    BuildContext context,
    User user,
    ThemeData theme,
    int territoriesCount,
    double totalArea,
  ) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(theme, Icons.bar_chart, 'Statistics'),
          const SizedBox(height: 12),
          _buildStatRow(theme, 'Total Distance', formatDistance(user.totalDistance), Icons.directions_run),
          const SizedBox(height: 8),
          _buildStatRow(theme, 'Kingdom Size', formatArea(totalArea), Icons.terrain),
          const SizedBox(height: 8),
          _buildStatRow(theme, 'Territories', '$territoriesCount', Icons.map),
          const SizedBox(height: 8),
          _buildStatRow(theme, 'Activity Streak', '${user.activityStreak} days', Icons.local_fire_department),
        ],
      ),
    );
  }

  // ─── Settings card ─────────────────────────────────────────────────────────

  Widget _buildSettingsCard(BuildContext context, ThemeData theme, bool isDark) {
    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(theme, Icons.settings, 'Settings'),
          const SizedBox(height: 8),
          Consumer<ThemeProvider>(
            builder: (_, themeProvider, __) => _toggleTile(
              theme: theme,
              isDark: isDark,
              icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: themeProvider.isDarkMode,
              onChanged: (_) => themeProvider.toggleTheme(),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared helpers ────────────────────────────────────────────────────────

  /// White-bg card container matching `bg-card / text-card-foreground`.
  Widget _card(ThemeData theme, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  /// Left-aligned section header with icon.
  Widget _cardHeader(ThemeData theme, IconData icon, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 10),
        Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatRow(ThemeData theme, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  /// Settings toggle tile — active = bg-primary, inactive = bg-input.
  Widget _toggleTile({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final primary    = theme.colorScheme.primary;
    final inputColor = isDark ? AppColors.darkInput : AppColors.input;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: inputColor,
          ),
        ],
      ),
    );
  }

}
