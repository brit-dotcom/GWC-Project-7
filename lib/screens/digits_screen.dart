import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../services/game_service.dart';

class DigitsScreen extends StatefulWidget {
  final Future<void> Function() onCoinsEarned;

  const DigitsScreen({super.key, required this.onCoinsEarned});

  @override
  State<DigitsScreen> createState() => _DigitsScreenState();
}

class _DigitsScreenState extends State<DigitsScreen> {
  final petService  = PetService();
  final gameService = GameService();

  // Available operators
  static const List<String> operators = ['+', '-', '×', '÷'];

  // Game state
  int target = 0;                      // the number to reach
  List<int?> numbers = [];             // current available numbers (null = used)
  List<int> originalNumbers = [];      // starting numbers for reset
  int? selectedNumber;                 // first number selected
  int? selectedIndex;                  // index of first selected number
  String? selectedOperator;            // operator chosen
  List<String> history = [];           // list of operations performed e.g. "3 + 4 = 7"
  bool gameOver = false;
  bool won = false;
  bool isLoading = true;
  bool onCooldown = false;
  String cooldownText = '';

  @override
  void initState() {
    super.initState();
    _checkCooldownAndInit();
  }

  Future<void> _checkCooldownAndInit() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final canPlay = await gameService.canPlayGame(userId, 'digits');
    final cooldown = await gameService.getCooldownText(userId, 'digits');
    setState(() {
      onCooldown = !canPlay;
      cooldownText = cooldown;
      isLoading = false;
    });
    if (canPlay) _initGame();
  }

  // Generate a solvable puzzle:
  // Pick 6 random numbers (1–25), then build a target by
  // combining some of them so we know a solution exists
  void _initGame() {
    final rand = Random();

    // Generate 6 starting numbers between 1 and 25
    final nums = List.generate(6, (_) => rand.nextInt(25) + 1);

    // Build target by applying 2–3 random operations on copies
    // so the puzzle is always solvable
    final tempNums = [...nums];
    tempNums.shuffle();
    int result = tempNums[0];
    for (int i = 1; i <= 2; i++) {
      final op = rand.nextInt(4);
      final next = tempNums[i];
      switch (op) {
        case 0: result = result + next;           break;
        case 1: result = (result - next).abs();   break;
        case 2: result = result * next;           break;
        case 3:
          // Only divide if it divides evenly
          if (next != 0 && result % next == 0) {
            result = result ~/ next;
          } else {
            result = result + next;
          }
          break;
      }
    }

    setState(() {
      originalNumbers = List.from(nums);
      numbers = nums.map((n) => n as int?).toList();
      target = result.abs().clamp(10, 999);
      selectedNumber = null;
      selectedIndex = null;
      selectedOperator = null;
      history = [];
      gameOver = false;
      won = false;
    });
  }

  // Step 1 — player taps a number
  void _onNumberTapped(int index) {
    if (gameOver) return;
    if (numbers[index] == null) return; // already used

    if (selectedNumber == null) {
      // No number selected yet — select this one
      setState(() {
        selectedNumber = numbers[index];
        selectedIndex = index;
        selectedOperator = null;
      });
    } else if (selectedOperator != null && index != selectedIndex) {
      // We have a first number and operator — apply operation
      _applyOperation(index);
    } else {
      // Tapping a different number before choosing operator — switch selection
      setState(() {
        selectedNumber = numbers[index];
        selectedIndex = index;
        selectedOperator = null;
      });
    }
  }

  // Step 2 — player taps an operator
  void _onOperatorTapped(String op) {
    if (gameOver) return;
    if (selectedNumber == null) return; // must select a number first
    setState(() => selectedOperator = op);
  }

  // Step 3 — apply the operation when second number is tapped
  void _applyOperation(int secondIndex) {
    final a = selectedNumber!;
    final b = numbers[secondIndex]!;
    int? result;

    switch (selectedOperator) {
      case '+': result = a + b;                                    break;
      case '-': result = (a - b).abs();                           break;
      case '×': result = a * b;                                    break;
      case '÷':
        // Only allow clean division
        if (b != 0 && a % b == 0) {
          result = a ~/ b;
        } else if (a != 0 && b % a == 0) {
          result = b ~/ a;
        }
        break;
    }

    if (result == null) {
      // Invalid operation — show snackbar and reset selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Division must be exact — try another operation')),
      );
      setState(() {
        selectedNumber = null;
        selectedIndex = null;
        selectedOperator = null;
      });
      return;
    }

    // Record the operation in history
    final operationText = '$a $selectedOperator $b = $result';

    setState(() {
      // Remove both used numbers, add the result in the first slot
      numbers[selectedIndex!] = result;
      numbers[secondIndex] = null;
      history.add(operationText);
      selectedNumber = null;
      selectedIndex = null;
      selectedOperator = null;
    });

    // Check if any remaining number equals the target
    _checkWin(result!);
  }

  Future<void> _checkWin(int latestResult) async {
    if (latestResult == target) {
      setState(() {
        gameOver = true;
        won = true;
      });

      final userId = FirebaseAuth.instance.currentUser!.uid;
      await petService.applyGameRound(userId, won: true);
      await gameService.recordGamePlayed(userId, 'digits');
      await widget.onCoinsEarned();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text('You solved it! 🎉'),
            content: Text('You reached $target!\n+10 coins earned!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context); // back to games
                },
                child: const Text('Back to games'),
              ),
            ],
          ),
        );
      }
    }
  }

  // Undo the last operation — restores the two numbers used
  void _undoLast() {
    if (history.isEmpty) return;

    // Parse the last operation string to recover the two original numbers
    // Format: "a op b = result"
    final last = history.last;
    final parts = last.split(' ');
    if (parts.length < 5) return;

    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[2]);
    final result = int.tryParse(parts[4]);

    if (a == null || b == null || result == null) return;

    setState(() {
      // Find the slot with the result and restore both original numbers
      final resultIndex = numbers.indexOf(result);
      if (resultIndex != -1) numbers[resultIndex] = a;

      // Put b back in the first null slot
      final nullIndex = numbers.indexOf(null);
      if (nullIndex != -1) numbers[nullIndex] = b;

      history.removeLast();
      selectedNumber = null;
      selectedIndex = null;
      selectedOperator = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (onCooldown) {
      return Scaffold(
        backgroundColor: Color.fromARGB(255, 235, 185, 201),
        appBar: AppBar(title: const Text('Digits')),
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
      backgroundColor: Color.fromARGB(255, 235, 185, 201),
      appBar: AppBar(
        title: const Text('Digits'),
        actions: [
          // Undo button
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: history.isEmpty ? null : _undoLast,
            tooltip: 'Undo last operation',
          ),
          // Reset button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _initGame,
            tooltip: 'Reset puzzle',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            // Target number
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: won ? Colors.green : Color.fromARGB(204, 192, 118, 145),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(color: Colors.white70, fontSize: 40),
                  ),
                  Text(
                    '$target',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 68,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Operation status — shows what's selected so far
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                selectedNumber == null
                    ? 'Select a number to start'
                    : selectedOperator == null
                        ? '$selectedNumber — now pick an operator'
                        : '$selectedNumber $selectedOperator — now pick a second number',
                style: const TextStyle(fontSize: 20, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 80),

            // Number tiles — 6 tiles, used ones are greyed out
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: List.generate(numbers.length, (index) {
                final num = numbers[index];
                final isSelected = selectedIndex == index;
                final isUsed = num == null;
                return GestureDetector(
                  onTap: isUsed ? null : () => _onNumberTapped(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: isUsed
                          ? Colors.grey.shade200
                          : isSelected
                              ? Color.fromARGB(204, 255, 255, 255)
                              : Color(0xFF97A13B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF97A13B)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isUsed ? '' : '$num',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Color(0xFF97A13B) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 100),

            // Operator buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: operators.map((op) {
                final isSelected = selectedOperator == op;
                return GestureDetector(
                  onTap: () => _onOperatorTapped(op),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? Color.fromARGB(255, 52, 198, 243) : const Color.fromARGB(255, 255, 255, 255),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Color.fromARGB(255, 52, 198, 243),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        op,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Color.fromARGB(255, 52, 198, 243),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Operation history
            if (history.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Steps:',
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                ),
              ),
              const SizedBox(height: 6),
              ...history.map((op) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  op,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }
}