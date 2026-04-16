import 'package:flutter/material.dart';
import 'color_sequence_screen.dart';
import 'memory_match_screen.dart';

class GamesScreen extends StatelessWidget {
  final Future<void> Function() onCoinsEarned;

  const GamesScreen({super.key, required this.onCoinsEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _GameTile(
              emoji: '🎨',
              title: 'Color Sequence',
              description: 'Watch the pattern, repeat it back. How far can you go?',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ColorSequenceScreen(
                    onRoundComplete: onCoinsEarned,
                  ),
                ),
              ),
            ),

            _GameTile(
              emoji: '🧠',
              title: 'Memory Match',
              description: 'Flip cards to find matching pairs. Can you clear the board?',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MemoryMatchScreen(
                    onCoinsEarned: onCoinsEarned,
                  ),
                ),
              ),
            ),

            // Add more _GameTile entries here as new games are built.
          ],
        ),
      ),
    );
  }
}

// ── Reusable game tile ────────────────────────────────────────────────────────

class _GameTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _GameTile({
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
