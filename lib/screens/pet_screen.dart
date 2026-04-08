import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

// Changed to StatefulWidget so we can show a loading state
// while Firestore is being updated
class PetScreen extends StatefulWidget {
  final Pet pet;
  final Future<void> Function() onAction;

  const PetScreen({super.key, required this.pet, required this.onAction});

  @override
  State<PetScreen> createState() => _PetScreenState();
}

class _PetScreenState extends State<PetScreen> {
  final petService = PetService();
  // Tracks which button is loading so we can show a spinner
  // on just that button without disabling the whole screen
  String? loadingAction;

  Future<void> handleFeed() async {
    setState(() => loadingAction = 'Feed');
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await petService.feedPet(userId, widget.pet.id, widget.pet.hunger);
      // Tell HomePage to refresh pet data so stats update on screen
      await widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => loadingAction = null);
    }
  }

  Future<void> handlePlay() async {
    setState(() => loadingAction = 'Play');
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await petService.playWithPet(
        userId,
        widget.pet.id,
        widget.pet.happiness,
        widget.pet.energy,
      );
      await widget.onAction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => loadingAction = null);
    }
  }

  Future<void> handleSleepWake() async {
    setState(() => loadingAction = 'SleepWake');
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
      setState(() => loadingAction = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4ECD4), Color(0xFFD4E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                widget.pet.name,
                style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Your Digital Pet',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Pet sprite card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('🐾', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4ECD4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getMoodMessage(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Stats card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildStatRow('🍎', 'Hunger', widget.pet.hunger, Colors.green),
                    const SizedBox(height: 16),
                    _buildStatRow('❤️', 'Happiness', widget.pet.happiness, Colors.pink),
                    const SizedBox(height: 16),
                    _buildStatRow('⚡', 'Energy', widget.pet.energy, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons — now wired up to real handlers
              Row(
                children: [
                  _buildActionButton(
                    'Feed',
                    Icons.apple,
                    const Color(0xFF4CAF82),
                    handleFeed,
                    'Feed',
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    'Play',
                    Icons.auto_awesome,
                    const Color(0xFFE91E8C),
                    handlePlay,
                    'Play',
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    widget.pet.isAsleep ? 'Wake' : 'Sleep',
                    widget.pet.isAsleep ? Icons.wb_sunny : Icons.nightlight_round,
                    const Color(0xFFFF9800),
                    handleSleepWake,
                    'SleepWake',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.black45),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Care for your pet by feeding, playing, and resting. Earn coins by completing Pomodoro study sessions!',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Coin counter
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFC107),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.monetization_on, color: Colors.white, size: 20),
                    SizedBox(width: 6),
                    Text(
                      '0',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodMessage() {
    if (widget.pet.isAsleep) return '${widget.pet.name} is sleeping... 💤';
    if (widget.pet.happiness < 30) return '${widget.pet.name} is feeling lonely...';
    if (widget.pet.hunger < 30) return '${widget.pet.name} is hungry...';
    if (widget.pet.energy < 30) return '${widget.pet.name} is tired...';
    return '${widget.pet.name} is happy to see you!';
  }

  Widget _buildStatRow(String emoji, String label, int value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            Text(
              '$value/100',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  // Now takes an onPressed handler and an actionKey for the loading state
  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    Future<void> Function() onPressed,
    String actionKey,
  ) {
    final isLoading = loadingAction == actionKey;
    return Expanded(
      child: ElevatedButton(
        // Disable all buttons while any action is in progress
        onPressed: loadingAction != null ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          children: [
            // Show spinner on the tapped button, icon on the others
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}