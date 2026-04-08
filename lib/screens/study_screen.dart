import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';

// Two timer mode options
enum TimerMode {
  short, // 25 min focus, 5 min break, 20 coins
  long,  // 45 min focus, 10 min break, 50 coins
}

// Whether we're in focus time or break time
enum TimerPhase { focus, breakTime }

class StudyScreen extends StatefulWidget {
  final Future<void> Function() onSessionComplete;

  const StudyScreen({super.key, required this.onSessionComplete});

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
  int secondsRemaining = 25 * 60; // starts at 25 minutes

  // Tracks completed sessions this screen session
  int sessionsCompleted = 0;

  // Coin rewards per mode
  static const int shortReward = 20;
  static const int longReward = 50;

  // Focus durations in minutes per mode
  int get focusMinutes => selectedMode == TimerMode.short ? 25 : 45;
  int get breakMinutes => selectedMode == TimerMode.short ? 5 : 10;
  int get coinReward => selectedMode == TimerMode.short ? shortReward : longReward;

  @override
  void dispose() {
    // Always cancel the timer when leaving the screen
    // to prevent memory leaks
    _timer?.cancel();
    super.dispose();
  }

  // Switch between short and long mode — only allowed when timer is stopped
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

    // Tick every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining > 0) {
        setState(() => secondsRemaining--);
      } else {
        // Time's up — handle phase transition
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

  // Called when a focus or break phase finishes
  Future<void> _onPhaseComplete() async {
    if (currentPhase == TimerPhase.focus) {
      // Focus session done — award coins and move to break
      await _awardCoins();
      setState(() {
        currentPhase = TimerPhase.breakTime;
        secondsRemaining = breakMinutes * 60;
        sessionsCompleted++;
      });
      _showCompletionSnackbar('Focus session complete! +$coinReward coins earned 🎉');
    } else {
      // Break done — reset back to focus phase
      setState(() {
        currentPhase = TimerPhase.focus;
        secondsRemaining = focusMinutes * 60;
      });
      _showCompletionSnackbar('Break over! Ready for another session?');
    }
  }

  Future<void> _awardCoins() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await petService.addCoins(userId, coinReward);
      // Tell HomePage to refresh so coin counter updates
      await widget.onSessionComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not award coins: $e')),
        );
      }
    }
  }

  void _showCompletionSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Formats seconds into MM:SS display (e.g. 1500 → "25:00")
  String get timerDisplay {
    final minutes = secondsRemaining ~/ 60;
    final seconds = secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Progress from 0.0 to 1.0 for the progress bar
  double get timerProgress {
    final totalSeconds = currentPhase == TimerPhase.focus
        ? focusMinutes * 60
        : breakMinutes * 60;
    return 1 - (secondsRemaining / totalSeconds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Mode selector — disabled while timer is running
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
                    child: const Text('25 / 5 min\n+20 coins',
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
                    child: const Text('45 / 10 min\n+50 coins',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Phase label (Focus Time / Break Time)
            Text(
              currentPhase == TimerPhase.focus ? '📚 Focus Time' : '☕ Break Time',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Timer countdown display
            Text(
              timerDisplay,
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: timerProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                currentPhase == TimerPhase.focus
                    ? Colors.deepPurple
                    : Colors.green,
              ),
            ),
            const SizedBox(height: 24),

            // Play/Pause and Reset buttons
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
                  child: Icon(isRunning ? Icons.pause : Icons.play_arrow, size: 32),
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

            // Sessions completed + coin reward info
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
                            fontSize: 28, fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text('Sessions', style: TextStyle(color: Colors.black54)),
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
                        const Icon(Icons.monetization_on, color: Colors.white, size: 24),
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