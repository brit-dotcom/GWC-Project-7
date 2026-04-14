import 'package:flutter/material.dart';
import '../models/pet.dart';

class WardrobeScreen extends StatelessWidget {
  final Pet pet;
  final Future<void> Function() onPurchase;

  const WardrobeScreen({
    super.key,
    required this.pet,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: const Center(child: Text('Wardrobe — coming soon!')),
    );
  }
}
