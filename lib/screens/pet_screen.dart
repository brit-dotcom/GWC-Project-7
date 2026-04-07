import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetScreen extends StatelessWidget {
  final Pet pet;
  final Future<void> Function() onAction;

  const PetScreen({super.key, required this.pet, required this.onAction});

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

              // Pet name + subtitle
              Text(
                pet.name,
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
                    // Placeholder — swap for real sprite later
                    const Text('🐾', style: TextStyle(fontSize: 80)),
                    const SizedBox(height: 12),

                    // Mood message bubble
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
                    _buildStatRow('🍎', 'Hunger', pet.hunger, Colors.green),
                    const SizedBox(height: 16),
                    _buildStatRow('❤️', 'Happiness', pet.happiness, Colors.pink),
                    const SizedBox(height: 16),
                    _buildStatRow('⚡', 'Energy', pet.energy, Colors.orange),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Feed, Play, Sleep/Wake buttons
              Row(
                children: [
                  _buildActionButton('Feed', Icons.apple, const Color(0xFF4CAF82)),
                  const SizedBox(width: 12),
                  _buildActionButton('Play', Icons.auto_awesome, const Color(0xFFE91E8C)),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    pet.isAsleep ? 'Wake' : 'Sleep',
                    pet.isAsleep ? Icons.wb_sunny : Icons.nightlight_round,
                    const Color(0xFFFF9800),
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

  // Mood message changes based on stats
  String _getMoodMessage() {
    if (pet.isAsleep) return '${pet.name} is sleeping... 💤';
    if (pet.happiness < 30) return '${pet.name} is feeling lonely...';
    if (pet.hunger < 30) return '${pet.name} is hungry...';
    if (pet.energy < 30) return '${pet.name} is tired...';
    return '${pet.name} is happy to see you!';
  }

  // Stat label + progress bar
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

  // Single action button
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          // TODO: wire up Phase 4 interactions
        },
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
            Icon(icon, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }
}