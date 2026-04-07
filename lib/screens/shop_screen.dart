import 'package:flutter/material.dart';
import '../models/pet.dart';

class ShopScreen extends StatelessWidget {
  final Pet pet;
  // Called after a purchase so HomePage refreshes coin count
  final Future<void> Function() onPurchase;

  const ShopScreen({super.key, required this.pet, required this.onPurchase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: const Center(child: Text('Shop coming soon!')),
    );
  }
}