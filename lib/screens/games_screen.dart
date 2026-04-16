import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet.dart';
import 'color_sequence_screen.dart';
import 'memory_match_screen.dart';

class GamesScreen extends StatelessWidget {
  final Pet pet;
  final Future<void> Function() onCoinsEarned;

  const GamesScreen({
    super.key,
    required this.pet,
    required this.onCoinsEarned,
  });

  Widget _buildPetSprite() {
    if (pet.type == PetType.bunny) {
      final path = switch (pet.level) {
        PetLevel.baby  => 'assets/bb_b_wings.png',
        PetLevel.kid   => 'assets/kid_b_wings.png',
        PetLevel.adult => 'assets/adult_b_wings.png',
      };
      return Image.asset(path, width: 200, height: 200);
    }
    final emoji = switch (pet.type) {
      PetType.cat  => '🐱',
      PetType.deer => '🦌',
      _            => '🐰',
    };
    return Text(emoji, style: const TextStyle(fontSize: 72));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Games',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 235, 185, 201),
      ),
      backgroundColor: const Color.fromARGB(255, 235, 185, 201),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            children: [
              _buildPetSprite(),
              const SizedBox(height: 8),
              Text(
                '${pet.name} wants to play!',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 240,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _GameButton(
                        emoji: '🎨',
                        title: 'Color Sequence',
                        description:
                            'Watch the pattern, repeat it back.\nHow far can you go?',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ColorSequenceScreen(
                              onRoundComplete: onCoinsEarned,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _GameButton(
                        emoji: '🧠',
                        title: 'Memory Match',
                        description:
                            'Flip cards to find matching pairs.\nCan you clear the board?',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryMatchScreen(
                              onCoinsEarned: onCoinsEarned,
                            ),
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
      ),
    );
  }
}

// ── Game button ───────────────────────────────────────────────────────────────

class _GameButton extends StatefulWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _GameButton({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  State<_GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<_GameButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF97A13B),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.emoji, style: const TextStyle(fontSize: 62)),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
