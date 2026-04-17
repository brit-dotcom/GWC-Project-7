import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';

class PantryScreen extends StatefulWidget {
  final Pet pet;
  final Future<void> Function() onPurchase;

  const PantryScreen({super.key, required this.pet, required this.onPurchase});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  final _petService = PetService();
  late Pet _pet;
  String? _loadingFoodId;

  @override
  void initState() {
    super.initState();
    _pet = widget.pet;
  }

  Future<void> _feed(FoodItem food) async {
    setState(() => _loadingFoodId = food.id);
    try {
      final updated = _pet.applyFood(food);
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await _petService.savePet(userId, updated);
      setState(() => _pet = updated);
      await widget.onPurchase();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${food.name} fed to ${_pet.name}!')),
        );
      }
    } on InsufficientCoinsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingFoodId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Food Pantry',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 185, 201),
      ),
      body: Stack(
        children: [
          // ── Background image ──────────────────
          Image.asset(
            'assets/pantry.jpg',         // ← swap for your filename
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Content ───────────────────────────
          Column(
            children: [

              // ── Coin balance banner ───────────
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFC107)),
                    const SizedBox(width: 6),
                    Text(
                      '${_pet.coins} coins',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Food grid ────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: kFoodPantry.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,   // slightly taller to fit text
                    ),
                    itemBuilder: (context, index) {
                      final food = kFoodPantry[index];
                      final canAfford = _pet.coins >= food.cost;
                      final isLoading = _loadingFoodId == food.id;

                      return _FoodSlot(
                        food: food,
                        canAfford: canAfford,
                        isLoading: isLoading,
                        onTap: (canAfford && !isLoading) ? () => _feed(food) : null,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Food slot card ────────────────────────────────────────────────────────────

class _FoodSlot extends StatelessWidget {
  final FoodItem food;
  final bool canAfford;
  final bool isLoading;
  final VoidCallback? onTap;

  const _FoodSlot({
    required this.food,
    required this.canAfford,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: canAfford ? 1.0 : 0.45,   // dim if can't afford
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // Food emoji
              isLoading
                  ? const SizedBox(
                      width: 38,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      food.icon,
                      style: const TextStyle(fontSize: 15),
                    ),

              const SizedBox(height: 4),

              // Food name
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 2),

              // Cost
              Text(
                '${food.cost} 🪙',
                style: const TextStyle(fontSize: 15),
              ),

              const SizedBox(height: 2),

              // Stats
              Text(
                '🍖+${food.hungerGain}  😊+${food.happinessGain}',
                style: const TextStyle(fontSize: 15, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
        ),
      ),
    );
  }
}