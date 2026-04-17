import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
 
class PetScreen extends StatefulWidget {
  final Pet pet;
 
  // Called after any action that modifies the pet so HomePage
  // can re-fetch and pass down the updated pet.
  final Future<void> Function() onAction;
 
  // Navigation callbacks — wired up in HomePage.
  final VoidCallback onOpenGames;
  final VoidCallback onOpenPomodoro;
  final VoidCallback onOpenPantry;
  final VoidCallback onOpenWardrobe;
 
  const PetScreen({
    super.key,
    required this.pet,
    required this.onAction,
    required this.onOpenGames,
    required this.onOpenPomodoro,
    required this.onOpenPantry,
    required this.onOpenWardrobe,
  });
 
  @override
  State<PetScreen> createState() => _PetScreenState();
}
 
class _PetScreenState extends State<PetScreen>
    with SingleTickerProviderStateMixin {
  final petService = PetService();
 
  // Controls the ZZZ animation shown while the pet is asleep.
  late final AnimationController _zzzController;
  late final Animation<double>   _zzzOpacity;
 
  bool isSleepLoading = false;

  // Egg hatching state — only used when widget.pet.isHatched is false
  int  _eggTapCount      = 0;
  bool _isHatching       = false; // true after 3rd tap, prevents further taps
  bool _showBabyPreview  = false; // true once the 3-second wait finishes
 
  @override
  void initState() {
    super.initState();
    _zzzController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
 
    _zzzOpacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _zzzController, curve: Curves.easeInOut),
    );
  }
 
  @override
  void dispose() {
    _zzzController.dispose();
    super.dispose();
  }
 
  // ── Egg hatching ─────────────────────────────

  Future<void> _handleEggTap() async {
    if (_isHatching) return;
    setState(() => _eggTapCount++);
    if (_eggTapCount < 3) return;

    setState(() => _isHatching = true);
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    setState(() => _showBabyPreview = true);
    final userId = FirebaseAuth.instance.currentUser!.uid;
    await petService.markPetHatched(userId, widget.pet.id);
    await widget.onAction();
  }

  List<String> _eggStages() {
    final up = switch (widget.pet.type) {
      PetType.bunny => 'B',
      PetType.cat   => 'C',
      PetType.deer  => 'D',
    };
    final lo = up.toLowerCase();
    return [
      'assets/pixelEggs/${up}_egg_full.png',
      'assets/pixelEggs/${lo}_small_crack.png',
      'assets/pixelEggs/${lo}_mo_crack.png',
      'assets/pixelEggs/${up}_cracked.png',
    ];
  }

  String _petSpritePath(PetType type, PetLevel level) {
    final prefix = switch (type) {
      PetType.bunny => 'b',
      PetType.cat   => 'cat',
      PetType.deer  => 'deer',
    };
    return switch (level) {
      PetLevel.baby  => 'assets/bb_${prefix}_wings.png',
      PetLevel.kid   => 'assets/kid_${prefix}_wings.png',
      PetLevel.adult => 'assets/adult_${prefix}_wings.png',
    };
  }

  // ── Sleep / wake ─────────────────────────────

  Future<void> handleSleepWake() async {
    setState(() => isSleepLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      if (widget.pet.isAsleep) {
        await petService.wakeUp(userId, widget.pet.id);
      } else {
        await petService.putToSleep(userId, widget.pet.id);
      }
      await widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => isSleepLoading = false);
    }
  }
 
  // ── Helpers ──────────────────────────────────
 
  /// Returns the placeholder emoji for the current pet type.
  /// Replace with Image.asset(widget.pet.spriteAsset) once
  /// designer assets are ready.
  String get _petEmoji {
    switch (widget.pet.type) {
      case PetType.bunny: return '🐰';
      case PetType.cat:   return '🐱';
      case PetType.deer:  return '🦌';
    }
  }
 
  String get _moodMessage {
    final name = widget.pet.name;
    if (widget.pet.isAsleep)          return '$name is sleeping...';
    if (widget.pet.happiness < 30)    return '$name is feeling bored...';
    if (widget.pet.hunger    < 30)    return '$name is hungry...';
    if (widget.pet.energy    < 30)    return '$name is tired...';
    return '$name is happy to see you!';
  }
 
  // ── Build ─────────────────────────────────────

  Widget _buildEggHatchingScreen() {
    final pet = widget.pet;

    Widget centerContent;
    if (_showBabyPreview) {
      centerContent = Image.asset(
        _petSpritePath(pet.type, PetLevel.baby),
        width: 200,
        height: 200,
      );
    } else {
      final stages   = _eggStages();
      final eggImage = Image.asset(
        stages[_eggTapCount.clamp(0, 3)],
        width: 200,
        height: 200,
      );
      centerContent = _isHatching
          ? eggImage
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _handleEggTap,
                child: eggImage,
              ),
            );
    }

    final instructionText = _showBabyPreview
        ? '${pet.name} has hatched!'
        : switch (_eggTapCount) {
            0 => 'Tap the egg 3 times to hatch your pet!',
            1 => '2 more taps!',
            2 => '1 more tap!',
            _ => 'Your pet is hatching...',
          };

    return Stack(
      children: [
        Image.asset(
          'assets/Petlivingroombackground.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.transparent),
        ),
        SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pet.name,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 32),
                centerContent,
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color:  Color.fromARGB(255, 143, 161, 102).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    instructionText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pet.isHatched) {
      return _buildEggHatchingScreen();
    }

    final pet       = widget.pet;
    final isAsleep  = pet.isAsleep;
 
    return Stack(
      children: [
        // ── Background ──────────────────────────
        Image.asset(
          'assets/Petlivingroombackground.png',
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),

        // Blur layer over the background image
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Container(color: Colors.transparent),
        ),

        // Dark overlay when the pet is sleeping
        if (isAsleep)
          Container(
            color: Colors.black.withValues(alpha: 0.6),
          ),
 
        SafeArea(
          child: Column(
            children: [
              // ── Top bar ────────────────────────
              _buildTopBar(pet, isAsleep),
 
              // ── Pet sprite area ────────────────
              Expanded(
                child: Center(
                  child: _buildPetSprite(pet, isAsleep),
                ),
              ),
 
              // ── Mood message ───────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  _moodMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: isAsleep ? Colors.white60 : Colors.black,
                  ),
                ),
              ),
 
              // ── Stat bars ──────────────────────
              _buildStatBars(pet, isAsleep),
 
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
 
  // ── Top bar ───────────────────────────────────
  //
  // Layout:
  //   LEFT  column : Pomodoro button, Games button
  //   CENTER       : Coins indicator, Level indicator
  //   RIGHT column : Wardrobe button, Pantry button, Sleep button
 
  Widget _buildTopBar(Pet pet, bool isAsleep) {
    final labelColor = isAsleep ? Colors.white70 : Colors.black87;
 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Pomodoro + Games ─────────────
          Column(
            children: [
              _buildNavButton(
                icon: Icons.timer_outlined,
                label: 'Study',
                color: const Color(0xFF7B5EA7),
                isAsleep: isAsleep,
                onTap: isAsleep ? null : widget.onOpenPomodoro,
              ),
              const SizedBox(height: 8),
              _buildNavButton(
                icon: Icons.sports_esports_outlined,
                label: 'Games',
                color: const Color(0xFFE91E8C),
                isAsleep: isAsleep,
                onTap: isAsleep ? null : widget.onOpenGames,
              ),
            ],
          ),
 
          // ── Center: Coins + Level ──────────────
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                // Coins badge
                _buildBadge(
                  icon: Icons.monetization_on,
                  iconColor: const Color(0xFFFFC107),
                  label: '${pet.coins}',
                  labelColor: labelColor,
                  isAsleep: isAsleep,
                ),
                const SizedBox(height: 6),
                // Level badge
                _buildBadge(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFF4CAF82),
                  label: pet.levelName,
                  labelColor: labelColor,
                  isAsleep: isAsleep,
                ),
              ],
            ),
          ),
 
          // ── Right: Wardrobe + Pantry + Sleep ───
          Column(
            children: [
              _buildNavButton(
                icon: Icons.checkroom_outlined,
                label: 'Wardrobe',
                color: const Color(0xFF5C9BD6),
                isAsleep: isAsleep,
                onTap: isAsleep ? null : widget.onOpenWardrobe,
              ),
              const SizedBox(height: 8),
              _buildNavButton(
                icon: Icons.restaurant_outlined,
                label: 'Pantry',
                color: const Color(0xFF4CAF82),
                isAsleep: isAsleep,
                onTap: isAsleep ? null : widget.onOpenPantry,
              ),
              const SizedBox(height: 8),
              // Sleep button is always tappable (to wake up too)
              _buildNavButton(
                icon: isAsleep
                    ? Icons.wb_sunny_outlined
                    : Icons.bedtime_outlined,
                label: isAsleep ? 'Wake' : 'Sleep',
                color: const Color(0xFFFF9800),
                isAsleep: false, // never grey out the sleep button
                onTap: isSleepLoading ? null : handleSleepWake,
                isLoading: isSleepLoading,
              ),
            ],
          )
        ],
      ),
    );
  }
 
  // ── Pet sprite ────────────────────────────────
 
  Widget _buildPetSprite(Pet pet, bool isAsleep) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: isAsleep ? 0.6 : 1.0,
          child: Image.asset(
            _petSpritePath(pet.type, pet.level),
            width: 350,
            height: 350,
          ),
        ),
        // ZZZ animation — only shown while asleep
        if (isAsleep)
          Positioned(
            top: -30,
            right: -30,
            child: FadeTransition(
              opacity: _zzzOpacity,
              child: const Text(
                'z z z',
                style: TextStyle(
                  fontSize: 40,//22 before
                  color: Colors.white70,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
      ],
    );
  }
 
  // ── Stat bars ─────────────────────────────────
  //
  // Displayed at the bottom of the screen, display-only.
 
  Widget _buildStatBars(Pet pet, bool isAsleep) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isAsleep
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildStatRow(
            emoji: '🍎',
            label: 'Hunger',
            value: pet.hunger,
            color: const Color(0xFF97A13B),
            isAsleep: isAsleep,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            emoji: '❤️',
            label: 'Happiness',
            value: pet.happiness,
            color: const Color.fromARGB(204, 230, 153, 184),
            isAsleep: isAsleep,
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            emoji: '⚡',
            label: 'Energy',
            value: pet.energy,
            color: const Color.fromARGB(255, 181, 242, 251),
            isAsleep: isAsleep,
          ),
        ],
      ),
    );
  }
 
  Widget _buildStatRow({
    required String emoji,
    required String label,
    required int value,
    required Color color,
    required bool isAsleep,
  }) {
    final textColor = isAsleep ? Colors.white60 : Colors.black87;
    final trackColor = isAsleep
        ? Colors.white.withOpacity(0.12)
        : Colors.grey.shade200;
 
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 20, color: textColor),
            ),
            const Spacer(),
            Text(
              '$value/100',
              style: TextStyle(fontSize: 18, color: textColor.withOpacity(0.7)),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 9,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              isAsleep ? color.withOpacity(0.4) : color,
            ),
          ),
        ),
      ],
    );
  }
 
  // ── Shared widget builders ────────────────────
 
  /// Small icon + label button used in the top-left and top-right columns.
  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isAsleep,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return _NavButton(
      icon: icon,
      label: label,
      color: color,
      isAsleep: isAsleep,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
 
  /// Coin / level badge shown in the top-center.
  Widget _buildBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required bool isAsleep,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isAsleep
            ? Colors.white.withOpacity(0.08)
            : Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 20,
            color: isAsleep ? iconColor.withOpacity(0.4) : iconColor,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav button with hover effect ─────────────────────────────────────────────

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isAsleep;
  final VoidCallback? onTap;
  final bool isLoading;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.isAsleep,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.isAsleep ? widget.color.withValues(alpha: 0.5) : widget.color;

    // Brighten the box and strengthen the shadow on hover
    final boxColor = widget.isAsleep
        ? Colors.white.withValues(alpha: 0.15)
        : _hovered
            ? Colors.white.withValues(alpha: 1.0)
            : Colors.white.withValues(alpha: 0.85);

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: (_hovered && !widget.isAsleep && widget.onTap != null) ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: boxColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: widget.isAsleep
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: _hovered ? 0.28 : 0.15,
                            ),
                            blurRadius: _hovered ? 10 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: widget.isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: effectiveColor,
                        ),
                      )
                    : Icon(widget.icon, color: effectiveColor, size: 45),
              ),
              const SizedBox(height: 3),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}