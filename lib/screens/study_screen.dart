import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import 'package:google_fonts/google_fonts.dart';

enum TimerMode { short, long }
enum TimerPhase { focus, breakTime }

class StudyScreen extends StatefulWidget {
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

  TimerMode selectedMode = TimerMode.short;
  TimerPhase currentPhase = TimerPhase.focus;

  Timer? _timer;
  bool isRunning = false;
  int secondsRemaining = 25 * 60;
  int sessionsCompleted = 0;

  int get focusMinutes => selectedMode == TimerMode.short ? 25 : 45;
  int get breakMinutes => selectedMode == TimerMode.short ? 5 : 10;
  int get coinReward => selectedMode == TimerMode.short ? 20 : 40;

  String get _petEmoji {
    switch (widget.pet.type) {
      case PetType.bunny: return '🐰';
      case PetType.cat:   return '🐱';
      case PetType.deer:  return '🦌';
    }
  }

  Widget _buildPetSprite() {
    if (widget.pet.type == PetType.bunny) {
      final path = switch (widget.pet.level) {
        PetLevel.baby  => 'assets/bb_b_wings.png',
        PetLevel.kid   => 'assets/kid_b_wings.png',
        PetLevel.adult => 'assets/adult_b_wings.png',
      };
      return Image.asset(path, width: 100, height: 100);
    }
    return Text(_petEmoji, style: const TextStyle(fontSize: 72));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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

  Future<void> _onPhaseComplete() async {
    if (currentPhase == TimerPhase.focus) {
      await _awardCoins();
      setState(() {
        currentPhase = TimerPhase.breakTime;
        secondsRemaining = breakMinutes * 60;
        sessionsCompleted++;
      });
      _showSnackbar('Focus session complete! +$coinReward coins earned 🎉');
    } else {
      setState(() {
        currentPhase = TimerPhase.focus;
        secondsRemaining = focusMinutes * 60;
      });
      _showSnackbar('Break over! Ready for another session?');
    }
  }

  Future<void> _awardCoins() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final currentPet = await petService.getPet(userId);
      if (currentPet == null) return;

      final updatedPet = currentPet.applyPomodoroSession(focusMinutes);
      await petService.savePet(userId, updatedPet);
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
          .showSnackBar(SnackBar(content: Text(message, style: GoogleFonts.playfairDisplay())));
    }
  }

  String get timerDisplay {
    final m = secondsRemaining ~/ 60;
    final s = secondsRemaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  double get timerProgress {
    final total = currentPhase == TimerPhase.focus
        ? focusMinutes * 60
        : breakMinutes * 60;
    return 1 - (secondsRemaining / total);
  }

  @override
  Widget build(BuildContext context) {
    final isFocus = currentPhase == TimerPhase.focus;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Study Timer',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Color.fromARGB(255, 235, 185, 201),
      ),
      body: Stack(
        children:[
          Image.asset(
            'assets/bgss.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),  
        
      SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Pet sprite ───────────────────────
            _buildPetSprite(),
            Text(
              '${widget.pet.name} is studying with you!',
              style: GoogleFonts.playfairDisplay(
                fontSize: 16,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // ── Mode selector ────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? null : () => selectMode(TimerMode.short),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMode == TimerMode.short
                          ? Color.fromRGBO(224, 163, 187, 0.80) 
                          : Colors.grey.shade200,
                      foregroundColor: selectedMode == TimerMode.short
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: Text(
                      '25 / 5 min\n+20 coins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRunning ? null : () => selectMode(TimerMode.long),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedMode == TimerMode.long
                          ?Color.fromRGBO(224, 163, 187, 0.80) 
                          :  Color.fromRGBO(224, 163, 187, 0.80),
                      foregroundColor: selectedMode == TimerMode.long
                          ? Colors.white
                          : Colors.black87,
                    ),
                    child: Text(
                      '45 / 10 min\n+40 coins',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Phase label ──────────────────────
            Text(
              isFocus ? '📚 Focus Time' : '☕ Break Time',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── Countdown display ────────────────
            Text(
              timerDisplay,
              style: GoogleFonts.playfairDisplay(
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // ── Progress bar ─────────────────────
            LinearProgressIndicator(
              value: timerProgress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFocus ? Color.fromRGBO(224, 163, 187, 0.80) : Color(0xFF97A13B).withValues(alpha: 0.75),
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
                    backgroundColor: Color.fromRGBO(224, 163, 187, 0.80),
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

            // ── Stats row ────────────────────────
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF97A13B).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('🏆', style: TextStyle(fontSize: 24)),
                        Text(
                          '$sessionsCompleted',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Sessions',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.black54,
                          ),
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
                      color: Color(0xFF97A13B).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.monetization_on,
                          color: Color(0xFF97A13B).withValues(alpha: 0.75),
                          size: 24,
                        ),
                        Text(
                          '+$coinReward',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Per Session',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            ),
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
      ],
      ),
    );
  }
}