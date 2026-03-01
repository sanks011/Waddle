import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Shows the Topaz coin reward after a successful territory creation.
/// Call via [TopazRewardModal.show].
class TopazRewardModal extends StatefulWidget {
  final int topazEarned;
  final int totalTopaz;
  final VoidCallback onClaim;

  const TopazRewardModal({
    super.key,
    required this.topazEarned,
    required this.totalTopaz,
    required this.onClaim,
  });

  /// Convenience method — shows the modal as a dialog.
  static Future<void> show(
    BuildContext context, {
    required int topazEarned,
    required int totalTopaz,
    required VoidCallback onClaim,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => TopazRewardModal(
        topazEarned: topazEarned,
        totalTopaz: totalTopaz,
        onClaim: onClaim,
      ),
      transitionBuilder: (_, anim, __, child) {
        final curve = CurvedAnimation(parent: anim, curve: Curves.elasticOut);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.6, end: 1.0).animate(curve),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeIn),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TopazRewardModal> createState() => _TopazRewardModalState();
}

class _TopazRewardModalState extends State<TopazRewardModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;

    const goldStart = Color(0xFFFFD700);
    const goldEnd = Color(0xFFFF9800);
    const topazPurple = Color(0xFF7C3AED);

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: topazPurple.withOpacity(0.35),
                blurRadius: 40,
                spreadRadius: 2,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Reward banner header ──────────────────────────────────
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        'assets/award-reward.svg',
                        height: 96,
                        colorFilter: const ColorFilter.mode(
                          Colors.white,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Territory Claimed!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'You\'ve earned Topaz coins',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Coin amount ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                child: AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (_, __) {
                    final shimmer = _shimmerController.value;
                    return ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: const [
                          goldEnd,
                          goldStart,
                          Colors.white,
                          goldStart,
                          goldEnd,
                        ],
                        stops: [
                          0.0,
                          (shimmer - 0.2).clamp(0.0, 1.0),
                          shimmer.clamp(0.0, 1.0),
                          (shimmer + 0.2).clamp(0.0, 1.0),
                          1.0,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(bounds),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/coin-currency.svg',
                            height: 44,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '+${widget.topazEarned}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 52,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const Text(
                'Topaz',
                style: TextStyle(
                  color: Color(0xFF7C3AED),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),

              const SizedBox(height: 16),

              // ── Total balance ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: topazPurple.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white60 : Colors.black45,
                      ),
                    ),
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/coin-currency.svg',
                          height: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${widget.totalTopaz} Topaz',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Claim button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6D28D9), Color(0xFF7C3AED)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: topazPurple.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onClaim();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Claim',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
