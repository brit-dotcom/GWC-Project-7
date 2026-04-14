import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

// Two timer mode options
enum TimerMode {
  short, // 25 min focus, 5 min break  → 20 coins
  long,  // 45 min focus, 10 min break → 40 coins
}

// Whether we're in focus time or break time
enum TimerPhase { focus, breakTime }

class StudyScreen extends StatefulWidget {
  // Pet is passed in from HomePage so the sprite can be displayed.
  final Pet pet;
  final Future<void> Function() onSessionComplete;

  const StudyScreen({
    super.key,
    required this.pet,
    required this.onSessionComplete,
  });

  @override
  State<StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<StudyScreen> {
  final petService = PetService();

  // Current timer mode — defaults to short (25/5)
  TimerMode selectedMode = TimerMode.short;

  // Whether we're in focus or break phase
  TimerPhase currentPhase = TimerPhase.focus;

  // Timer state
  Timer? _timer;
  bool isRunning = false;
  int secondsRemaining = 25 * 60;

  // Tracks completed focus sessions this screen visit
  int sessionsCompleted = 0;

  // Focus/break durations per mode
  int get focusMinutes => selectedMode == TimerMode.short ? 25 : 45;
  int get breakMinutes => selectedMode == TimerMode.short ?  5 : 10;

  // Coin rewards matching game logic:
  //   25 min session (short) → 20 coins
  //   45 min session (long)  → 40 coins
  int get coinReward => selectedMode == TimerMode.short ? 20 : 40;

  // ── Placeholder sprite (swap for Image.asset once designer assets are ready)
  String get _petEmoji {
    switch (widget.pet.type) {
      case PetType.bunny: return '🐰';
      case PetType.cat:   return '🐱';
      case PetType.deer:  return '🦌';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Timer controls ───────────────────────────

  // Switch modes — only allowed when timer is stopped
  void selectMode(TimerMode mode) {
    if (isRunning) return;
    setState(() {
      selectedMode = mode;
      currentPhase = TimerPhase.focus;
      secondsRemaining = focusMinutes * 60;
    });
  }

  void startTimer() {
    setState(() => isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        _timer?.cancel();
        setState(() => isRunning = false);
        _onPhaseComplete();
      }
    });
  }

  void pauseTimer() {
    _timer?.cancel();
    setState(() => isRunning = false);
  }

  void resetTimer() {
    _timer?.cancel();
    setState(() {
      isRunning = false;
      currentPhase = TimerPhase.focus;
      secondsRemaining = focusMinutes * 60;
    });
  }

  // ── Phase completion ─────────────────────────

  Future<void> _onPhaseComplete() async {
    if (currentPhase == TimerPhase.focus) {
      // Focus session done — award coins then move to break
      await _awardCoins();
      setState(() {
        currentPhase = TimerPhase.breakTime;
        secondsRemaining = breakMinutes * 60;
        sessionsCompleted++;
      });
      _showSnackbar('Focus session complete! +$coinReward coins earned 🎉');
    } else {
      // Break done — reset back to focus
      setState(() {
        currentPhase = TimerPhase.focus;
        secondsRemaining = focusMinutes * 60;
      });
      _showSnackbar('Break over! Ready for another session?');
    }
  }

  // Awards coins by going through the pet model so BOTH coins and
  // totalCoinsEarned are updated correctly in Firestore.
  Future<void> _awardCoins() async {
    try {
      final userId     = FirebaseAuth.instance.currentUser!.uid;
      final currentPet = await petService.getPet(userId);
      if (currentPet == null) return;

      // applyPomodoroSession uses focusMinutes to determine the reward tier
      // and calls _earn() internally, which increments both coin fields.
      final updatedPet = currentPet.applyPomodoroSession(focusMinutes);
      await petService.savePet(userId, updatedPet);

      // Tell HomePage to refresh so the coin badge updates immediately
      await widget.onSessionComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not award coins: $e')),
        );
      }
    }
  }

  void _showSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ── Display helpers ──────────────────────────

  // Formats seconds as MM:SS (e.g. 1500 → "25:00")
  String get timerDisplay {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining  % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // 0.0 → 1.0 progress for the bar
  double get timerProgress {
    final total = currentPhase == TimerPhase.focus
        ? focusMinutes * 60
        : breakMinutes * 60;
    return 1 - (secondsRemaining / total);
  }

  // ── Build ─────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isFocus = currentPhase == TimerPhase.focus;

    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // ── Pet sprite ───────────────────────
            // Shows the pet watching over the study session.
            // Replace Text(_petEmoji) with Image.asset(widget.pet.spriteAsset)
            // once designer assets are in place.
            Text(
              _petEmoji,
              style: const TextStyle(fontSize: 72),
            ),
            Text(
              '${widget.pet.name} is studying with you!',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // ── Mode selector ────────────────────
            // Disabled while the timer is running.
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? null : () => selectMode(TimerMode.short),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMode == TimerMode.short
                          ? Colors.deepPurple
                          : Colors.grey.shade200,
                      foregroundColor: selectedMode == TimerMode.short
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: const Text(
                      '25 / 5 min\n+20 coins',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? null : () => selectMode(TimerMode.long),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMode == TimerMode.long
                          ? Colors.deepPurple
                          : Colors.grey.shade200,
                      foregroundColor: selectedMode == TimerMode.long
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: const Text(
                      '45 / 10 min\n+40 coins',  // fixed: was +50
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Phase label ──────────────────────
            Text(
              isFocus ? '📚 Focus Time' : '☕ Break Time',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── Countdown display ────────────────
            Text(
              timerDisplay,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // ── Progress bar ─────────────────────
            LinearProgressIndicator(
              value: timerProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFocus ? Colors.deepPurple : Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // ── Play / Pause + Reset ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isRunning ? pauseTimer : startTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                  ),
                  child: Icon(
                    isRunning ? Icons.pause : Icons.play_arrow,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  onPressed: resetTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    foregroundColor: Colors.black54,
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.replay, size: 32),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Stats row: sessions + coin reward ─
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 24)),
                        Text(
                          '$sessionsCompleted',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Sessions',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC107),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.monetization_on,
                          color: Colors.white,
                          size: 24,
                        ),
                        Text(
                          '+$coinReward',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Per Session',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}