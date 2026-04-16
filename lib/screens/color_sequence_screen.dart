import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

// ── Game state machine ────────────────────────────────────────────────────────

enum _GameState {
  idle,        // before the first round starts
  showing,     // sequence is being flashed to the player
  playerTurn,  // player is tapping colors
  gameOver,    // player tapped the wrong color
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ColorSequenceScreen extends StatefulWidget {
  // Called after every round (won or lost) so the home page coin badge
  // and stat bars refresh in real time.
  final Future<void> Function() onRoundComplete;

  const ColorSequenceScreen({super.key, required this.onRoundComplete});

  @override
  State<ColorSequenceScreen> createState() => _ColorSequenceScreenState();
}

// ── Color definitions ─────────────────────────────────────────────────────────

const _kButtonColors = [
  Colors.red,
  Colors.blue,
  Colors.green,
  Colors.amber,
];

const _kColorLabels = ['Red', 'Blue', 'Green', 'Yellow'];

// ── State ─────────────────────────────────────────────────────────────────────

class _ColorSequenceScreenState extends State<ColorSequenceScreen> {
  final _petService = PetService();
  final _random     = Random();

  // Grows by one each round.
  final List<int> _sequence = [];

  // Tracks how many colors the player has correctly tapped this round.
  final List<int> _playerInput = [];

  // Index of the button that is currently lit (null = all dim).
  int? _litIndex;

  _GameState _state = _GameState.idle;

  // How many rounds the player completed this game.
  int _roundsCompleted = 0;

  // ── Game flow ───────────────────────────────────────────────────────────────

  void _startGame() {
    _sequence.clear();
    _playerInput.clear();
    setState(() {
      _litIndex         = null;
      _state            = _GameState.showing;
      _roundsCompleted  = 0;
    });
    _beginNextRound();
  }

  void _beginNextRound() {
    _playerInput.clear();
    _sequence.add(_random.nextInt(4)); // add one new random color
    setState(() => _state = _GameState.showing);
    _playSequence();
  }

  Future<void> _playSequence() async {
    // Short pause so the player can get ready before the flash starts.
    await Future.delayed(const Duration(milliseconds: 700));

    for (final colorIndex in _sequence) {
      if (!mounted) return;

      // Light up.
      setState(() => _litIndex = colorIndex);
      await Future.delayed(const Duration(milliseconds: 600));

      // Dim.
      if (!mounted) return;
      setState(() => _litIndex = null);
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;
    setState(() => _state = _GameState.playerTurn);
  }

  // Called every time the player taps a color button.
  Future<void> _onPlayerTap(int index) async {
    if (_state != _GameState.playerTurn) return;

    // Briefly flash the tapped button so the player gets feedback.
    setState(() => _litIndex = index);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _litIndex = null);

    final expected = _playerInput.length;

    if (_sequence[expected] != index) {
      // Wrong color — game over.
      await _handleGameOver();
      return;
    }

    _playerInput.add(index);

    if (_playerInput.length == _sequence.length) {
      // Completed the full sequence — round won!
      await _handleRoundWon();
    }
  }

  Future<void> _handleRoundWon() async {
    _roundsCompleted++;
    await _applyRound(won: true);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Round $_roundsCompleted done! +$kCoinsPerGameWin coins 🎉',
        ),
        duration: const Duration(milliseconds: 1200),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pause before the next round's flash begins.
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    _beginNextRound();
  }

  Future<void> _handleGameOver() async {
    setState(() => _state = _GameState.gameOver);
    await _applyRound(won: false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wrong color! Game over.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Reads the latest pet from Firestore, applies the game round result
  // through the Pet model (which handles all stat + coin math), then saves.
  Future<void> _applyRound({required bool won}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final pet    = await _petService.getPet(userId);
      if (pet == null) return;

      final updated = pet.applyGameRound(won: won);
      await _petService.savePet(userId, updated);
      await widget.onRoundComplete();
    } catch (_) {
      // Silent fail — the game still plays even if Firestore is unreachable.
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color Sequence')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Status / instruction text
            _buildStatusText(),

            const SizedBox(height: 12),

            // Round counter (hidden on idle screen)
            if (_state != _GameState.idle)
              Text(
                'Round $_roundsCompleted',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
              ),

            const SizedBox(height: 32),

            // 2 × 2 color button grid
            Expanded(child: _buildGrid()),

            const SizedBox(height: 32),

            // Start / Play Again button (only shown when not mid-game)
            if (_state == _GameState.idle || _state == _GameState.gameOver)
              _buildStartButton(),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Sub-widgets ─────────────────────────────────────────────────────────────

  Widget _buildStatusText() {
    final String text;
    final Color color;

    switch (_state) {
      case _GameState.idle:
        text  = 'Press Start to play!';
        color = Colors.black87;
      case _GameState.showing:
        text  = 'Watch the sequence…';
        color = Colors.deepPurple;
      case _GameState.playerTurn:
        text  = 'Your turn! '
                '(${_playerInput.length} / ${_sequence.length})';
        color = Colors.teal.shade700;
      case _GameState.gameOver:
        text  = _roundsCompleted == 0
            ? 'Game over! Better luck next time.'
            : 'Game over! You completed $_roundsCompleted '
              '${_roundsCompleted == 1 ? 'round' : 'rounds'}.';
        color = Colors.red.shade700;
    }

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(4, _buildColorButton),
    );
  }

  Widget _buildColorButton(int index) {
    final isLit    = _litIndex == index;
    final canTap   = _state == _GameState.playerTurn;
    final baseColor = _kButtonColors[index];

    return GestureDetector(
      onTap: canTap ? () => _onPlayerTap(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: isLit
              ? baseColor
              : baseColor.withValues(alpha: 0.28),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isLit
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.65),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            _kColorLabels[index],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isLit
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton() {
    final isRestart = _state == _GameState.gameOver;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _startGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          isRestart ? 'Play Again' : 'Start',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
