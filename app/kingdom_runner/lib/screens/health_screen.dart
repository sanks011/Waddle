import 'dart:math' show sin, pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../providers/water_provider.dart';
import '../theme/app_theme.dart';
import '../services/water_notification_service.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isSavingGoal = false;
  int _calorieGoal = 2000;
  int _savedCalorieGoal = 2000;
  List<double> _weeklyExercise = [];
  List<double> _weeklyCalories = [];
  List<double> _avgExercise = List<double>.filled(7, 0.0);
  final List<String> _days = ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<WaterProvider>(context, listen: false).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Provider.of<WaterProvider>(context, listen: false).refresh();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    if (user?.dailyCalories != null) {
      setState(() {
        _calorieGoal = user!.dailyCalories!.toInt();
        _savedCalorieGoal = _calorieGoal;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final activityProvider =
        Provider.of<ActivityProvider>(context, listen: false);

    await Future.wait([
      authProvider.loadCurrentUser(),
      activityProvider.loadUserSessions(),
    ]);

    if (mounted) {
      final user = authProvider.currentUser;
      if (user?.dailyCalories != null) {
        _calorieGoal = user!.dailyCalories!.toInt();
      }
      _weeklyExercise = activityProvider.getWeeklyExerciseMinutes();
      _weeklyCalories = activityProvider.getWeeklyCaloriesBurned();
      _avgExercise = activityProvider.getAverageExerciseMinutesPerWeekday();
      _savedCalorieGoal = _calorieGoal;
      setState(() => _isLoading = false);
    }
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Health'),
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWaterCard(context, theme, isDark),
              const SizedBox(height: 16),
              _buildMoveGoalCard(context, theme, isDark),
              const SizedBox(height: 16),
              _buildExerciseMinutesCard(context, theme, isDark),
              const SizedBox(height: 120), // space so last card scrolls above dock
            ],
          ),
        ),
      ),
    );
  }

  // ─── Water Card ─────────────────────────────────────────────────────────────

  Widget _buildWaterCard(BuildContext context, ThemeData theme, bool isDark) {
    return Consumer<WaterProvider>(
      builder: (context, water, _) {
        if (!water.isSetup) {
          return _buildWaterSetupCta(context, theme, isDark);
        }
        return _buildWaterTracker(context, theme, isDark, water);
      },
    );
  }

  Widget _buildWaterSetupCta(
      BuildContext context, ThemeData theme, bool isDark) {
    return _card(
      theme,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.water_drop_rounded,
                size: 32, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text('Stay Hydrated',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            'Track your daily water intake and get reminders to drink water throughout the day.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showWaterSetupSheet(context),
              icon: const Icon(Icons.water_drop_outlined, size: 18),
              label: const Text('Get Started'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterTracker(BuildContext context, ThemeData theme, bool isDark,
      WaterProvider water) {
    final primary = theme.colorScheme.primary;
    final consumed = water.consumedMl;
    final goal = water.goalMl;
    final progressPct = (water.progress * 100).round();

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.water_drop_rounded, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Water Intake',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${consumed}ml / ${goal}ml',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              // Edit settings button
              IconButton(
                onPressed: () => _showWaterSetupSheet(context),
                icon: Icon(Icons.tune_rounded, size: 20, color: primary),
                style: IconButton.styleFrom(
                  backgroundColor: primary.withOpacity(0.1),
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Progress ring + liquid fill
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer arc ring
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: water.progress,
                      strokeWidth: 10,
                      backgroundColor: primary.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(primary),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  // Liquid fill inside the ring
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: _WaterLiquidWidget(
                      progress: water.progress,
                      color: primary,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$progressPct%',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: primary,
                            ),
                          ),
                          Text(
                            '${water.completedCount}/${water.servings}',
                            style: theme.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Serving chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(water.servings, (i) {
              final isDone = water.done[i];
              final t = water.getServingTime(i);
              final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
              final amPm = t.period == DayPeriod.am ? 'am' : 'pm';
              final label =
                  '$hour:${t.minute.toString().padLeft(2, '0')}$amPm';

              return GestureDetector(
                onTap: () => water.markServing(i, !isDone),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDone
                        ? primary.withOpacity(0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDone ? primary : theme.dividerColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isDone
                            ? Icons.water_drop_rounded
                            : Icons.water_drop_outlined,
                        size: 14,
                        color: isDone ? primary : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: isDone ? primary : theme.colorScheme.onSurface.withOpacity(0.6),
                          fontWeight:
                              isDone ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // Reset button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset Today?'),
                    content: const Text(
                        'This will clear all your water intake for today.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Reset')),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await Provider.of<WaterProvider>(context, listen: false)
                      .resetToday();
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Reset Today'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
                side: BorderSide(color: theme.dividerColor),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWaterSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _WaterSetupSheet(),
    );
  }

  // ─── Move Goal card (same as ProfileScreen) ─────────────────────────────────

  Widget _buildMoveGoalCard(BuildContext context, ThemeData theme, bool isDark) {
    final borderColor = theme.dividerColor;
    final mutedFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final accentBg = isDark ? AppColors.darkAccent : AppColors.accent;
    final accentFg = isDark
        ? AppColors.darkAccentForeground
        : AppColors.accentForeground;
    final secondaryBg = isDark ? AppColors.darkSecondary : AppColors.secondary;
    final secondaryFg = isDark
        ? AppColors.darkSecondaryForeground
        : AppColors.secondaryForeground;

    final weeklyCalories = _weeklyCalories.isEmpty
        ? List<double>.filled(7, 0.0)
        : _weeklyCalories;

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_run,
                    size: 18, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Move Goal',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Set your daily activity goal',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepperBtn(
                icon: Icons.remove,
                theme: theme,
                accentBg: accentBg,
                accentFg: accentFg,
                borderColor: borderColor,
                onTap: () => setState(
                    () => _calorieGoal = (_calorieGoal - 50).clamp(500, 5000)),
              ),
              const SizedBox(width: 28),
              Column(
                children: [
                  Text(
                    '$_calorieGoal',
                    style: theme.textTheme.displaySmall
                        ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0),
                  ),
                  Text('calories per day', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(width: 28),
              _stepperBtn(
                icon: Icons.add,
                theme: theme,
                accentBg: accentBg,
                accentFg: accentFg,
                borderColor: borderColor,
                onTap: () => setState(
                    () => _calorieGoal = (_calorieGoal + 50).clamp(500, 5000)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 110,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _days[v.toInt().clamp(0, 6)],
                          style: TextStyle(fontSize: 10, color: mutedFg),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: weeklyCalories[i],
                        color: theme.colorScheme.primary,
                        width: 14,
                        borderRadius: BorderRadius.circular(5),
                        borderSide: BorderSide(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                    ],
                  );
                }),
                maxY: _calorieGoal * 1.25,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: (_isSavingGoal || _calorieGoal == _savedCalorieGoal)
                  ? null
                  : () async {
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final apiService = authProvider.apiService;
                      setState(() => _isSavingGoal = true);
                      final updatedUser = await apiService
                          .updateDailyCalories(_calorieGoal.toDouble());
                      if (updatedUser != null && mounted) {
                        await authProvider.loadCurrentUser();
                        setState(() => _savedCalorieGoal = _calorieGoal);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Daily calorie goal set to $_calorieGoal kcal'),
                            backgroundColor: theme.colorScheme.primary,
                          ),
                        );
                      }
                      if (mounted) setState(() => _isSavingGoal = false);
                    },
              style: OutlinedButton.styleFrom(
                backgroundColor: _calorieGoal == _savedCalorieGoal
                    ? theme.colorScheme.primary.withOpacity(0.08)
                    : secondaryBg,
                foregroundColor: _calorieGoal == _savedCalorieGoal
                    ? theme.colorScheme.primary
                    : secondaryFg,
                side: BorderSide(
                  color: _calorieGoal == _savedCalorieGoal
                      ? theme.colorScheme.primary.withOpacity(0.4)
                      : borderColor,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSavingGoal
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_calorieGoal == _savedCalorieGoal) ...[
                          Icon(Icons.check_circle_outline_rounded,
                              size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _calorieGoal == _savedCalorieGoal
                              ? 'Goal Set'
                              : 'Set Goal',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Exercise Minutes card (same as ProfileScreen) ───────────────────────────

  Widget _buildExerciseMinutesCard(
      BuildContext context, ThemeData theme, bool isDark) {
    final borderColor = theme.dividerColor;
    final mutedFg =
        isDark ? AppColors.darkMutedForeground : AppColors.mutedForeground;
    final mutedBg = isDark ? AppColors.darkMuted : AppColors.muted;
    final primary = theme.colorScheme.primary;

    final exerciseData = _weeklyExercise.isEmpty
        ? List<double>.filled(7, 0.0)
        : _weeklyExercise;
    final todayIndex = DateTime.now().weekday - 1;
    final todayMins = exerciseData[todayIndex];
    final avgMins = _avgExercise[todayIndex];
    final String aheadStr;
    if (avgMins <= 0) {
      aheadStr = 'No history yet — keep moving!';
    } else {
      final pct = ((todayMins - avgMins) / avgMins * 100).round();
      aheadStr = pct >= 0
          ? '${pct}% ahead of where you normally are'
          : '${pct.abs()}% behind where you normally are';
    }

    return _card(
      theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    Icon(Icons.timer_outlined, size: 18, color: primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exercise Minutes',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(
                      'Your exercise minutes are $aheadStr.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: borderColor.withOpacity(0.5), strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: borderColor.withOpacity(0.5), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _days[v.toInt().clamp(0, 6)],
                          style: TextStyle(fontSize: 10, color: mutedFg),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                        7, (i) => FlSpot(i.toDouble(), _avgExercise[i])),
                    isCurved: true,
                    color: borderColor,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                        show: true, color: mutedBg.withOpacity(0.35)),
                  ),
                  LineChartBarData(
                    spots: List.generate(
                        7, (i) => FlSpot(i.toDouble(), exerciseData[i])),
                    isCurved: true,
                    color: primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, i) => FlDotCirclePainter(
                        radius: i == todayIndex ? 5 : 2.5,
                        color: i == todayIndex
                            ? primary
                            : primary.withOpacity(0.4),
                        strokeColor: Colors.transparent,
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                        show: true, color: primary.withOpacity(0.1)),
                  ),
                ],
                minX: 0,
                maxX: 6,
                minY: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(primary, 'Today'),
              const SizedBox(width: 16),
              _legendDot(borderColor, 'Average'),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Shared helpers ─────────────────────────────────────────────────────────

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

  Widget _stepperBtn({
    required IconData icon,
    required ThemeData theme,
    required Color accentBg,
    required Color accentFg,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        highlightColor: accentBg.withOpacity(0.4),
        splashColor: accentBg.withOpacity(0.6),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Icon(icon, size: 20, color: accentFg),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 18,
          height: 3,
          decoration:
              BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Builder(
          builder: (ctx) => Text(
            label,
            style: Theme.of(ctx).textTheme.labelSmall,
          ),
        ),
      ],
    );
  }
}

// ─── Water Setup Bottom Sheet ────────────────────────────────────────────────

class _WaterSetupSheet extends StatefulWidget {
  const _WaterSetupSheet();

  @override
  State<_WaterSetupSheet> createState() => _WaterSetupSheetState();
}

class _WaterSetupSheetState extends State<_WaterSetupSheet> {
  late int _goalMl;
  late int _servings;
  late TimeOfDay _startTime;
  late bool _notifEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final water = Provider.of<WaterProvider>(context, listen: false);
    _goalMl = water.goalMl;
    _servings = water.servings;
    _startTime = water.startTime;
    _notifEnabled = water.notifEnabled;
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      if (_notifEnabled) {
        final granted = await WaterNotificationService.requestPermissions();
        if (!granted && mounted) {
          setState(() => _notifEnabled = false); // fall back to no notifications
        }
      }
      if (mounted) {
        await Provider.of<WaterProvider>(context, listen: false).saveSettings(
          goalMl: _goalMl,
          servings: _servings,
          startTime: _startTime,
          notifEnabled: _notifEnabled,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final inputColor = isDark ? AppColors.darkInput : AppColors.input;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text('Water Setup',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Customize your hydration goals',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 24),

          // Daily goal slider
          Text('Daily Goal: ${_goalMl}ml',
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500)),
          Slider(
            value: _goalMl.toDouble(),
            min: 500,
            max: 5000,
            divisions: 18,
            label: '${_goalMl}ml',
            activeColor: primary,
            inactiveColor: primary.withOpacity(0.15),
            onChanged: (v) => setState(() => _goalMl = v.round()),
          ),
          const SizedBox(height: 16),

          // Servings stepper
          Row(
            children: [
              Expanded(
                child: Text('Servings per day',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w500)),
              ),
              _sheetStepBtn(
                icon: Icons.remove,
                theme: theme,
                inputColor: inputColor,
                onTap: () => setState(
                    () => _servings = (_servings - 1).clamp(4, 16)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_servings',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              _sheetStepBtn(
                icon: Icons.add,
                theme: theme,
                inputColor: inputColor,
                onTap: () => setState(
                    () => _servings = (_servings + 1).clamp(4, 16)),
              ),
            ],
          ),

          // Serving size info
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text(
              '≈ ${(_goalMl / _servings).round()}ml per serving',
              style: theme.textTheme.bodySmall,
            ),
          ),

          // Start time picker
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start Time',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text('First reminder of the day',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime,
                  );
                  if (picked != null) setState(() => _startTime = picked);
                },
                icon: const Icon(Icons.access_time_rounded, size: 16),
                label: Text(
                  () {
                    final h = _startTime.hourOfPeriod == 0
                        ? 12
                        : _startTime.hourOfPeriod;
                    final m = _startTime.minute.toString().padLeft(2, '0');
                    final p = _startTime.period == DayPeriod.am ? 'AM' : 'PM';
                    return '$h:$m $p';
                  }(),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Notifications toggle
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_active_outlined,
                    size: 18, color: primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reminders',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    Text('Push notifications when it\'s time to drink',
                        style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Switch(
                value: _notifEnabled,
                onChanged: (v) => setState(() => _notifEnabled = v),
                activeColor: Colors.white,
                activeTrackColor: primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: inputColor,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save',
                      style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sheetStepBtn({
    required IconData icon,
    required ThemeData theme,
    required Color inputColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Icon(icon, size: 18, color: theme.colorScheme.onSurface),
      ),
    );
  }
}

// ─── Animated liquid fill widget ─────────────────────────────────────────────

class _WaterLiquidWidget extends StatefulWidget {
  final double progress;
  final Color color;
  final Widget child;

  const _WaterLiquidWidget({
    required this.progress,
    required this.color,
    required this.child,
  });

  @override
  State<_WaterLiquidWidget> createState() => _WaterLiquidWidgetState();
}

class _WaterLiquidWidgetState extends State<_WaterLiquidWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => ClipOval(
        child: CustomPaint(
          painter: _WaterLiquidPainter(
            progress: widget.progress,
            phase: _ctrl.value * 2 * pi,
            color: widget.color,
          ),
          child: child,
        ),
      ),
      child: Center(child: widget.child),
    );
  }
}

class _WaterLiquidPainter extends CustomPainter {
  final double progress;
  final double phase;
  final Color color;

  const _WaterLiquidPainter({
    required this.progress,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final h = size.height;
    final fillY = h * (1.0 - progress.clamp(0.0, 1.0));
    const amplitude = 5.0;
    const frequency = 2.0;

    final path = Path();
    path.moveTo(0, fillY + sin(phase) * amplitude);
    for (double x = 0; x <= w; x++) {
      path.lineTo(
        x,
        fillY + sin(phase + (x / w) * frequency * 2 * pi) * amplitude,
      );
    }
    path.lineTo(w, h);
    path.lineTo(0, h);
    path.close();

    // Two-layer fill: deeper base + lighter foam/highlight at top
    final basePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.25),
          color.withOpacity(0.45),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(path, basePaint);

    // Subtle foam highlight at wave crest
    final foamPath = Path();
    foamPath.moveTo(0, fillY + sin(phase) * amplitude);
    for (double x = 0; x <= w; x++) {
      foamPath.lineTo(
        x,
        fillY + sin(phase + (x / w) * frequency * 2 * pi) * amplitude,
      );
    }
    foamPath.lineTo(w, fillY + amplitude + 6);
    foamPath.lineTo(0, fillY + amplitude + 6);
    foamPath.close();

    canvas.drawPath(
      foamPath,
      Paint()..color = color.withOpacity(0.18),
    );
  }

  @override
  bool shouldRepaint(_WaterLiquidPainter old) =>
      old.progress != progress || old.phase != phase || old.color != color;
}
