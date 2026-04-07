import 'package:flutter/material.dart';
import '../models/pet.dart';

class PetScreen extends StatelessWidget {
  // Pet data passed in from HomePage
  final Pet pet;
  // Called after feed/play/sleep so HomePage refreshes stats
  final Future<void> Function() onAction;

  const PetScreen({super.key, required this.pet, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(pet.name)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🐾', style: const TextStyle(fontSize: 80)),
            Text('Hunger: ${pet.hunger}/100'),
            Text('Happiness: ${pet.happiness}/100'),
            Text('Energy: ${pet.energy}/100'),
            Text('Health: ${pet.health}/100'),
          ],
        ),
      ),
    );
  }
}