import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../services/game_service.dart';

class MemoryMatchScreen extends StatefulWidget {
  final Future<void> Function() onCoinsEarned;

  const MemoryMatchScreen({super.key, required this.onCoinsEarned});

  @override
  State<MemoryMatchScreen> createState() => _MemoryMatchScreenState();
}

class _MemoryMatchScreenState extends State<MemoryMatchScreen> {
  final petService  = PetService();
  final gameService = GameService();

  // The 8 emoji pairs used in the game — 16 cards total
  static const List<String> _emojis = [
    '🐱', '🐶', '🐰', '🦊', '🐸', '🐼', '🐨', '🦁',
  ];

  // Game state
  List<String> cards = [];           // all 16 cards in shuffled order
  List<bool> flipped = [];           // which cards are face up
  List<bool> matched = [];           // which cards are permanently matched
  int? firstFlippedIndex;            // index of first card flipped this turn
  bool canFlip = true;               // prevents flipping during mismatch delay
  int moves = 0;                     // total moves made
  int matchesFound = 0;              // pairs matched so far
  bool gameOver = false;
  bool isLoading = true;             // waiting for cooldown check
  bool onCooldown = false;           // can't play yet
  String cooldownText = '';          // e.g. "3h 42m"

  @override
  void initState() {
    super.initState();
    _checkCooldownAndInit();
  }

  Future<void> _checkCooldownAndInit() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final canPlay = await gameService.canPlayGame(userId, 'memoryMatch');
    final cooldown = await gameService.getCooldownText(userId, 'memoryMatch');

    setState(() {
      onCooldown = !canPlay;
      cooldownText = cooldown;
      isLoading = false;
    });

    // Only set up the board if the player can actually play
    if (canPlay) _initBoard();
  }

  // Shuffles the 16 cards and resets all game state
  void _initBoard() {
    final allCards = [..._emojis, ..._emojis]; // duplicate for pairs
    allCards.shuffle(Random());
    setState(() {
      cards = allCards;
      flipped = List.filled(16, false);
      matched = List.filled(16, false);
      firstFlippedIndex = null;
      canFlip = true;
      moves = 0;
      matchesFound = 0;
      gameOver = false;
    });
  }

  Future<void> _onCardTapped(int index) async {
    // Ignore taps on already matched/flipped cards or during delay
    if (!canFlip) return;
    if (matched[index]) return;
    if (flipped[index]) return;

    setState(() => flipped[index] = true);

    if (firstFlippedIndex == null) {
      // First card of the pair — just record it
      firstFlippedIndex = index;
    } else {
      // Second card — check for match
      moves++;
      final first = firstFlippedIndex!;
      firstFlippedIndex = null;

      if (cards[first] == cards[index]) {
        // Match found!
        setState(() {
          matched[first] = true;
          matched[index] = true;
          matchesFound++;
        });

        // Check if all 8 pairs are matched
        if (matchesFound == 8) {
          await _onGameWon();
        }
      } else {
        // No match — flip both cards back after a short delay
        setState(() => canFlip = false);
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          flipped[first] = false;
          flipped[index] = false;
          canFlip = true;
        });
      }
    }
  }

  Future<void> _onGameWon() async {
    setState(() => gameOver = true);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Award coins and apply game effects to pet stats
    await petService.applyGameRound(userId, won: true);

    // Start the 4 hour cooldown
    await gameService.recordGamePlayed(userId, 'memoryMatch');

    // Refresh home screen coin display
    await widget.onCoinsEarned();

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('You won! 🎉'),
          content: Text(
            'You matched all pairs in $moves moves!\n+${10} coins earned!',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back to games screen
              },
              child: const Text('Back to games'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show cooldown screen if game isn't available yet
    if (onCooldown) {
      return Scaffold(
        appBar: AppBar(title: const Text('Memory Match')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('⏳', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'Game on cooldown',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Available in $cooldownText',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Memory Match')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Moves: $moves',
                  style: const TextStyle(fontSize: 16),
                ),
                Text('Matches: $matchesFound / 8',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4x4 card grid — LayoutBuilder measures the exact space
            // available so the aspect ratio is calculated dynamically,
            // ensuring all 16 cards fit on screen without any scrolling.
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  const columns = 4;
                  const rows    = 4;
                  final cardW = (constraints.maxWidth  - spacing * (columns - 1)) / columns;
                  final cardH = (constraints.maxHeight - spacing * (rows    - 1)) / rows;

                  return GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      childAspectRatio: cardW / cardH,
                    ),
                    itemCount: 16,
                    itemBuilder: (context, index) {
                      final isFlipped = flipped[index] || matched[index];
                      return GestureDetector(
                        onTap: () => _onCardTapped(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            color: matched[index]
                                ? Colors.green.shade100
                                : isFlipped
                                    ? Colors.deepPurple.shade100
                                    : Colors.deepPurple,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: matched[index]
                                  ? Colors.green
                                  : Colors.deepPurple,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              isFlipped ? cards[index] : '?',
                              style: TextStyle(
                                fontSize: 28,
                                color: isFlipped ? null : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}