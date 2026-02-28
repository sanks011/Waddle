import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 5;
  bool _hasSwipedOnce = false;

  // Onboarding data
  DateTime? _selectedDOB;
  double _weight = 70;
  double _heightCm = 170;
  double _dailyProtein = 50;
  double _dailyCarbs = 250;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skipAll() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.skipOnboarding();
    if (mounted) _goToDashboard();
  }

  void _completeOnboarding() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.saveOnboardingData(
      dateOfBirth: _selectedDOB,
      weight: _weight,
      height: _heightCm,
      dailyProtein: _dailyProtein,
      dailyCarbs: _dailyCarbs,
    );
    if (mounted) _goToDashboard();
  }

  void _goToDashboard() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          final tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/Login.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFDE978), Color(0xFFF5B04A)],
                  ),
                ),
              );
            },
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Progress + Skip
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      // Progress dots
                      Expanded(
                        child: Row(
                          children: List.generate(_totalPages, (i) {
                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                height: 4,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: i <= _currentPage
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Skip button
                      if (_currentPage < _totalPages - 1)
                        GestureDetector(
                          onTap: _skipAll,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                        if (!_hasSwipedOnce) _hasSwipedOnce = true;
                      });
                    },
                    children: [
                      _buildDOBPage(),
                      _buildWeightPage(),
                      _buildHeightPage(),
                      _buildDietPage(),
                      _buildCompletePage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Step 1: Date of Birth
  // ─────────────────────────────────────────────
  Widget _buildDOBPage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/birthday-calender.svg',
                    width: 56, height: 56,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'When\'s your birthday?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This helps us personalize your experience',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // iOS-style Date Picker Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 60,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Selected date display
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedDOB != null
                                    ? '${_getMonthName(_selectedDOB!.month)} ${_selectedDOB!.day}, ${_selectedDOB!.year}'
                                    : 'Select Date',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: -0.408,
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Color(0xFFFF3B30), size: 20),
                            ],
                          ),
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        // Calendar (using Flutter's built-in)
                        SizedBox(
                          height: 300,
                          child: Theme(
                            data: ThemeData.light().copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFFFF3B30),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: CalendarDatePicker(
                              initialDate: _selectedDOB ?? DateTime(2000, 1, 1),
                              firstDate: DateTime(1940),
                              lastDate: DateTime.now(),
                              onDateChanged: (date) {
                                setState(() => _selectedDOB = date);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  if (!_hasSwipedOnce) _buildSwipeHint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Step 2: Weight
  // ─────────────────────────────────────────────
  Widget _buildWeightPage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/weight-1.svg',
                    width: 56, height: 56,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'What\'s your weight?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll track your progress over time',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Weight display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _weight.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          ' kg',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF007AFF),
                      inactiveTrackColor: const Color(0x33787880),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF007AFF).withOpacity(0.1),
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 14),
                    ),
                    child: Slider(
                      value: _weight,
                      min: 30,
                      max: 200,
                      onChanged: (v) => setState(() => _weight = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30 kg',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                        Text('200 kg',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Step 3: Height
  // ─────────────────────────────────────────────
  Widget _buildHeightPage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/height.svg',
                    width: 56, height: 56,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How tall are you?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Helps calculate your fitness metrics',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Height display
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _heightCm.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          ' cm',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_heightCm / 30.48).floor()}\'${((_heightCm / 2.54) % 12).round()}" ft',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: const Color(0xFF007AFF),
                      inactiveTrackColor: const Color(0x33787880),
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF007AFF).withOpacity(0.1),
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 14),
                    ),
                    child: Slider(
                      value: _heightCm,
                      min: 100,
                      max: 250,
                      onChanged: (v) => setState(() => _heightCm = v),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('100 cm',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                        Text('250 cm',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 12)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Step 4: Diet
  // ─────────────────────────────────────────────
  Widget _buildDietPage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/food-nutrition.svg',
                    width: 56, height: 56,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Daily Nutrition',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'How much do you consume daily?',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Protein
                  _buildNutrientInput(
                    label: 'Protein',
                    value: _dailyProtein,
                    unit: 'g/day',
                    min: 0,
                    max: 300,
                    color: const Color(0xFF4ECDC4),
                    icon: Icons.egg_outlined,
                    onChanged: (v) => setState(() => _dailyProtein = v),
                  ),
                  const SizedBox(height: 28),

                  // Carbs
                  _buildNutrientInput(
                    label: 'Carbs',
                    value: _dailyCarbs,
                    unit: 'g/day',
                    min: 0,
                    max: 500,
                    color: const Color(0xFFFF6B6B),
                    icon: Icons.grain,
                    onChanged: (v) => setState(() => _dailyCarbs = v),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInput({
    required String label,
    required double value,
    required String unit,
    required double min,
    required double max,
    required Color color,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(0)} $unit',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: Colors.white.withOpacity(0.15),
            thumbColor: Colors.white,
            overlayColor: color.withOpacity(0.1),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  Step 5: Complete!
  // ─────────────────────────────────────────────
  Widget _buildCompletePage() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkmark circle
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF007AFF),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF007AFF).withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.check_rounded,
                        size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'You\'re all set!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your profile is ready.\nLet\'s start conquering!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.white.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Summary
                  if (_selectedDOB != null || _weight != 70 || _heightCm != 170)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Column(
                        children: [
                          if (_selectedDOB != null)
                            _buildSummaryRow(
                                Icons.cake_outlined,
                                'Birthday',
                                '${_getMonthName(_selectedDOB!.month)} ${_selectedDOB!.day}, ${_selectedDOB!.year}'),
                          if (_weight != 70)
                            _buildSummaryRow(
                                Icons.monitor_weight_outlined,
                                'Weight',
                                '${_weight.toStringAsFixed(0)} kg'),
                          if (_heightCm != 170)
                            _buildSummaryRow(Icons.height, 'Height',
                                '${_heightCm.toStringAsFixed(0)} cm'),
                          _buildSummaryRow(Icons.egg_outlined, 'Protein',
                              '${_dailyProtein.toStringAsFixed(0)} g/day'),
                          _buildSummaryRow(Icons.grain, 'Carbs',
                              '${_dailyCarbs.toStringAsFixed(0)} g/day'),
                        ],
                      ),
                    ),

                  const SizedBox(height: 28),

                  // Go to Dashboard button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF007AFF),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF007AFF).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Go to Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white.withOpacity(0.6)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Shared Widgets
  // ─────────────────────────────────────────────
  Widget _buildGlassCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeHint() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.swipe, size: 18, color: Colors.white.withOpacity(0.4)),
        const SizedBox(width: 8),
        Text(
          'Swipe to continue',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.arrow_forward_ios, size: 12, color: Colors.white.withOpacity(0.4)),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
