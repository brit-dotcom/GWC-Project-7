import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import '../models/pet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final petService = PetService();
  final authService = AuthService();

  // Holds the pet data once loaded — null until Firestore responds
  Pet? pet;

  // Controls the loading spinner while fetching pet data
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load pet data as soon as the screen opens
    loadPet();
  }

  Future<void> loadPet() async {
    // Get the current user's ID to look up their pet
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fetchedPet = await petService.getPet(userId);

    // Update the UI with the fetched pet
    setState(() {
      pet = fetchedPet;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background matching Figma design
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFD4ECD4), Color(0xFFD4E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: isLoading
              // Show spinner while waiting for Firestore
              ? const Center(child: CircularProgressIndicator())
              : pet == null
                  // Fallback if something went wrong
                  ? const Center(child: Text('No pet found.'))
                  // Main pet screen
                  : _buildPetScreen(),
        ),
      ),
    );
  }

  Widget _buildPetScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          // Pet name as the page title
          Text(
            pet!.name,
            style: const TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'Your Digital Pet',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 16),

          // White card showing the pet sprite + mood message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                // Placeholder — replace with real sprite image later
                const Text('🐾', style: TextStyle(fontSize: 80)),
                const SizedBox(height: 12),

                // Mood message bubble — update this based on stats later
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4ECD4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${pet!.name} is happy to see you!',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // White card showing hunger, happiness, energy bars
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildStatRow('🍎', 'Hunger', pet!.hunger, Colors.green),
                const SizedBox(height: 16),
                _buildStatRow('❤️', 'Happiness', pet!.happiness, Colors.pink),
                const SizedBox(height: 16),
                _buildStatRow('⚡', 'Energy', pet!.energy, Colors.orange),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Feed, Play, Sleep action buttons
          Row(
            children: [
              _buildActionButton('Feed', Icons.apple, const Color(0xFF4CAF82)),
              const SizedBox(width: 12),
              _buildActionButton('Play', Icons.auto_awesome, const Color(0xFFE91E8C)),
              const SizedBox(width: 12),
              _buildActionButton('Sleep', Icons.nightlight_round, const Color(0xFF7C6FCD)),
            ],
          ),
          const SizedBox(height: 16),

          // Info banner at the bottom
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

          // Coin counter — hardcoded to 0 for now, wire up in Phase 4
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

          // Temporary logout button — move this to a settings page later
          const SizedBox(height: 20),
          TextButton(
            onPressed: () async => await authService.signOut(),
            child: const Text('Log out', style: TextStyle(color: Colors.black45)),
          ),
        ],
      ),
    );
  }

  // Builds a single stat row: icon + label + value + progress bar
  Widget _buildStatRow(String emoji, String label, int value, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14)),
            const Spacer(),
            // Shows e.g. "73/100"
            Text(
              '$value/100',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Progress bar — value/100 gives a 0.0 to 1.0 fill amount
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

  // Builds one of the three action buttons (Feed, Play, Sleep)
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          // TODO: wire up Phase 4 interactions (feedPet, playWithPet, putToSleep)
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