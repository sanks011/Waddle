import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  // null = idle; 'bomb' | 'scanner' | 'defuse' | 'nuke' = buying in progress
  String? _buyingItem;
  String? _feedback;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _buyBomb(BuildContext context) async {
    if (_buyingItem != null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() { _buyingItem = 'bomb'; _feedback = null; });
    try {
      final result = await auth.apiService.buyBomb();
      await auth.loadCurrentUser();
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = 'Bomb purchased! You now have ${result['bombsOwned'] ?? '?'} bomb(s).';
          _feedbackIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = e.toString().replaceFirst('Exception: ', '');
          _feedbackIsError = true;
        });
      }
    }
  }

  Future<void> _buyScannerDock(BuildContext context) async {
    if (_buyingItem != null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() { _buyingItem = 'scanner'; _feedback = null; });
    try {
      final result = await auth.apiService.buyScannerDock();
      await auth.loadCurrentUser();
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = 'Scanner Dock purchased! You now have ${result['scannerDocksOwned'] ?? '?'} dock(s).';
          _feedbackIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = e.toString().replaceFirst('Exception: ', '');
          _feedbackIsError = true;
        });
      }
    }
  }

  Future<void> _buyDefuseGun(BuildContext context) async {
    if (_buyingItem != null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() { _buyingItem = 'defuse'; _feedback = null; });
    try {
      final result = await auth.apiService.buyDefuseGun();
      await auth.loadCurrentUser();
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = 'Defuse Gun purchased! You now have ${result['defuseGunsOwned'] ?? '?'} gun(s).';
          _feedbackIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = e.toString().replaceFirst('Exception: ', '');
          _feedbackIsError = true;
        });
      }
    }
  }

  Future<void> _buyNuke(BuildContext context) async {
    if (_buyingItem != null) return;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    setState(() { _buyingItem = 'nuke'; _feedback = null; });
    try {
      final result = await auth.apiService.buyNuke();
      await auth.loadCurrentUser();
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = "Nuke purchased! You now have ${result['nukesOwned'] ?? '?'} nuke(s).";
          _feedbackIsError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _buyingItem = null;
          _feedback = e.toString().replaceFirst('Exception: ', '');
          _feedbackIsError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final coins = user?.topazCoins ?? 0;
    final bombs = user?.bombInventory ?? 0;
    final scannerDocks = user?.scannerDockInventory ?? 0;
    final defuseGuns = user?.defuseGunInventory ?? 0;
    final nukes = user?.nukeInventory ?? 0;

    final bgColor =
        isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F5FB);
    final cardColor =
        isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final accentPurple = const Color(0xFF7B2FBE);
    final accentOrange = const Color(0xFFFF6B35);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/shield-defense.svg',
              width: 26,
              height: 26,
            ),
            const SizedBox(width: 10),
            Text(
              'Kingdom Armory',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Topaz coin balance chip
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentOrange.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: accentOrange.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/coin-currency.svg',
                  width: 18,
                  height: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  '$coins',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accentOrange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Inventory banner ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentPurple.withOpacity(0.85),
                    accentPurple.withOpacity(0.55),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentPurple.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Inventory',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InventoryChip(
                        svgAsset: 'assets/explosive-bomb.svg',
                        label: '$bombs Bomb${bombs == 1 ? '' : 's'}',
                      ),
                      const SizedBox(width: 10),
                      _InventoryChip(
                        svgAsset: 'assets/dog.svg',
                        label: '$scannerDocks Dock${scannerDocks == 1 ? '' : 's'}',
                      ),
                      const SizedBox(width: 10),
                      _InventoryChip(
                        svgAsset: 'assets/lasergun.svg',
                        label: '$defuseGuns Gun${defuseGuns == 1 ? '' : 's'}',
                      ),
                      const SizedBox(width: 10),
                      _InventoryChip(
                        svgAsset: 'assets/nuke.svg',
                        label: '$nukes Nuke${nukes == 1 ? '' : 's'}',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Items for Sale',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // ── Bomb item card ────────────────────────────────────────
            _GadgetItemCard(
              cardColor: cardColor,
              accentColor: accentPurple,
              accentOrange: accentOrange,
              coins: coins,
              price: 50,
              svgAsset: 'assets/explosive-bomb.svg',
              name: 'Defence Bomb',
              description: 'Place on territory to damage invaders',
              isBuying: _buyingItem == 'bomb',
              onBuy: () => _buyBomb(context),
              shimmerController: _shimmerController,
            ),

            const SizedBox(height: 16),

            // ── Scanner Dock item card ──────────────────────────────────────────
            _GadgetItemCard(
              cardColor: cardColor,
              accentColor: const Color(0xFF0891B2), // cyan-600
              accentOrange: accentOrange,
              coins: coins,
              price: 80,
              svgAsset: 'assets/dog.svg',
              name: 'Scanner Dock',
              description: 'Reveals enemy bomb positions while invading',
              isBuying: _buyingItem == 'scanner',
              onBuy: () => _buyScannerDock(context),
              shimmerController: _shimmerController,
            ),

            const SizedBox(height: 16),

            // ── Defuse Gun item card ─────────────────────────────────────────────
            _GadgetItemCard(
              cardColor: cardColor,
              accentColor: const Color(0xFF059669), // emerald-600
              accentOrange: accentOrange,
              coins: coins,
              price: 120,
              svgAsset: 'assets/lasergun.svg',
              name: 'Defuse Gun',
              description: 'Permanently disables one enemy bomb when tapped on map',
              isBuying: _buyingItem == 'defuse',
              onBuy: () => _buyDefuseGun(context),
              shimmerController: _shimmerController,
            ),

            const SizedBox(height: 16),

            // ── Nuke item card ─────────────────────────────────────────────
            _GadgetItemCard(
              cardColor: cardColor,
              accentColor: const Color(0xFFDC2626), // red-600
              accentOrange: accentOrange,
              coins: coins,
              price: 10000,
              svgAsset: 'assets/nuke.svg',
              name: 'NUKE',
              description: 'Nuclear strike — destroys invader\'s territory when defending',
              isBuying: _buyingItem == 'nuke',
              onBuy: () => _buyNuke(context),
              shimmerController: _shimmerController,
            ),

            const SizedBox(height: 20),

            // ── How it works section ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: theme.dividerColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: accentPurple,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How Bombs Work',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: accentPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _HowItWorksRow(
                    icon: Icons.security,
                    text: 'Place bombs on your own territories via the territory stats sheet.',
                  ),
                  const SizedBox(height: 8),
                  _HowItWorksRow(
                    icon: Icons.local_fire_department,
                    text: 'Enemy hits a bomb: loses 50% health and 30 Topaz per bomb triggered.',
                  ),
                  const SizedBox(height: 8),
                  _HowItWorksRow(
                    icon: Icons.search,
                    text: 'Scanner Dock (80): activate mid-invasion to reveal enemy bomb positions as yellow pins.',
                  ),
                  const SizedBox(height: 8),
                  _HowItWorksRow(
                    icon: Icons.gpp_good_rounded,
                    text: 'Defuse Gun (120): tap a yellow pin on the map to permanently destroy that bomb.',
                  ),
                  const SizedBox(height: 8),
                  _HowItWorksRow(
                    icon: Icons.inventory_2_rounded,
                    text: 'Max 3 bombs per territory. Scanner Dock and Defuse Gun are consumed on use.',
                  ),
                ],
              ),
            ),

            // ── Feedback banner ───────────────────────────────────────
            if (_feedback != null) ...[
              const SizedBox(height: 16),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _feedbackIsError
                      ? Colors.red.withOpacity(0.15)
                      : Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _feedbackIsError
                        ? Colors.red.withOpacity(0.4)
                        : Colors.green.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _feedbackIsError
                          ? Icons.error_outline_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _feedbackIsError ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _feedback!,
                        style: TextStyle(
                          color: _feedbackIsError ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Small chip used in the inventory banner.
class _InventoryChip extends StatelessWidget {
  final String? svgAsset;
  final IconData? icon;
  final String label;
  const _InventoryChip({this.svgAsset, this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(svgAsset!, width: 20, height: 20)
            else if (icon != null)
              Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

/// Generic shop item card for any gadget.
class _GadgetItemCard extends StatelessWidget {
  final Color cardColor;
  final Color accentColor;
  final Color accentOrange;
  final int coins;
  final int price;
  final String? svgAsset;
  final IconData? icon;
  final String name;
  final String description;
  final bool isBuying;
  final VoidCallback onBuy;
  final AnimationController shimmerController;

  const _GadgetItemCard({
    required this.cardColor,
    required this.accentColor,
    required this.accentOrange,
    required this.coins,
    required this.price,
    this.svgAsset,
    this.icon,
    required this.name,
    required this.description,
    required this.isBuying,
    required this.onBuy,
    required this.shimmerController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAfford = coins >= price;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withOpacity(0.3)),
            ),
            child: Center(
              child: svgAsset != null
                  ? SvgPicture.asset(svgAsset!, width: 38, height: 38)
                  : Icon(icon ?? Icons.help, size: 38, color: accentColor),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SvgPicture.asset('assets/coin-currency.svg', width: 16, height: 16),
                    const SizedBox(width: 5),
                    Text(
                      '$price Topaz',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: accentOrange,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: ElevatedButton(
              onPressed: canAfford && !isBuying ? onBuy : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? accentColor : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isBuying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Buy', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _HowItWorksRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HowItWorksRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}
