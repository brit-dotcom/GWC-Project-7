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
      final userId  = FirebaseAuth.instance.currentUser!.uid;
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
      appBar: AppBar(title: const Text('Food Pantry')),
      body: Column(
        children: [
          // Coin balance banner
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

          // Food list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kFoodPantry.length,
              itemBuilder: (context, index) {
                final food      = kFoodPantry[index];
                final canAfford = _pet.coins >= food.cost;
                final isLoading = _loadingFoodId == food.id;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Text(
                      food.icon,
                      style: const TextStyle(fontSize: 36),
                    ),
                    title: Text(food.name),
                    subtitle: Text(
                      '+${food.hungerGain} hunger  '
                      '+${food.happinessGain} happiness  '
                      '+${food.energyGain} energy',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      onPressed: (canAfford && !isLoading)
                          ? () => _feed(food)
                          : null,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('${food.cost} 🪙'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
