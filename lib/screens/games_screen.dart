import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pet.dart';
import 'color_sequence_screen.dart';
import 'memory_match_screen.dart';
import 'digits_screen.dart';

class GamesScreen extends StatelessWidget {
  final Pet pet;
  final Future<void> Function() onCoinsEarned;

  const GamesScreen({
    super.key,
    required this.pet,
    required this.onCoinsEarned,
  });

  Widget _buildPetSprite(double size) {
    if (pet.type == PetType.bunny) {
      final path = switch (pet.level) {
        PetLevel.baby  => 'assets/bb_b_wings.png',
        PetLevel.kid   => 'assets/kid_b_wings.png',
        PetLevel.adult => 'assets/adult_b_wings.png',
      };
      return Image.asset(path, width: size, height: size);
    }

    final emoji = switch (pet.type) {
      PetType.cat  => '🐱',
      PetType.deer => '🦌',
      _            => '🐰',
    };

    return Text(emoji, style: TextStyle(fontSize: size * 0.4));
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

      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // 🔥 Responsive logic
          int crossAxisCount = width > 900 ? 3 : 2;
          double aspectRatio = width > 900 ? 1.1 : 0.85;

          double petSize = height * 0.22;
          double titleSize = width > 900 ? 16 : 18;
          double descSize = width > 900 ? 12 : 14;
          double emojiSize = width > 900 ? 32 : 40;

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                _buildPetSprite(petSize),
                const SizedBox(height: 8),
                Text(
                  '${pet.name} wants to play!',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: aspectRatio,
                    children: [
                      _GameButton(
                        emoji: '🎨',
                        title: 'Color Sequence',
                        description:
                            'Watch the pattern, repeat it back.\nHow far can you go?',
                        titleSize: titleSize,
                        descSize: descSize,
                        emojiSize: emojiSize,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ColorSequenceScreen(
                              onRoundComplete: onCoinsEarned,
                            ),
                          ),
                        ),
                      ),
                      _GameButton(
                        emoji: '🧠',
                        title: 'Memory Match',
                        description:
                            'Flip cards to find matching pairs.\nCan you clear the board?',
                        titleSize: titleSize,
                        descSize: descSize,
                        emojiSize: emojiSize,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MemoryMatchScreen(
                              onCoinsEarned: onCoinsEarned,
                            ),
                          ),
                        ),
                      ),
                      _GameButton(
                        emoji: '🔢',
                        title: 'Digits',
                        description:
                            'Remember and repeat the number sequence.\nTest your focus!',
                        titleSize: titleSize,
                        descSize: descSize,
                        emojiSize: emojiSize,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DigitsScreen(
                              onCoinsEarned: onCoinsEarned,
                            ),
                          ),
                        ),
                      ),
                      _GameButton(
                        emoji: '⚡',
                        title: 'Coming Soon',
                        description:
                            'A new challenge is on the way.\nStay tuned!',
                        titleSize: titleSize,
                        descSize: descSize,
                        emojiSize: emojiSize,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This game is coming soon!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Game button ─────────────────────────────────────────

class _GameButton extends StatefulWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  final double titleSize;
  final double descSize;
  final double emojiSize;

  const _GameButton({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
    required this.titleSize,
    required this.descSize,
    required this.emojiSize,
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
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF97A13B),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.emoji,
                      style: TextStyle(fontSize: widget.emojiSize)),
                  const SizedBox(height: 6),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: widget.titleSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: widget.descSize,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.3,
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