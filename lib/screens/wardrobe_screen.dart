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

  static const List<Map<String, dynamic>> _wardrobeItems = [
    {'icon': Icons.checkroom, 'label': 'Hat'},
    {'icon': Icons.checkroom, 'label': 'Earrings'},
    {'icon': Icons.watch, 'label': 'Necklace'},
    {'icon': Icons.backpack, 'label': 'Beanie'},
    {'icon': Icons.diamond, 'label': 'Ring'},
    {'icon': Icons.face, 'label': 'Glasses'},
    {'icon': Icons.badge, 'label': 'Badge'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wardrobe')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final accessory = _wardrobeItems[index];
            return AccessorySlot(
              icon: accessory['icon'] as IconData,
              label: accessory['label'] as String,
              onTap: () async {
                await onPurchase();
              },
            );
          },
        ),
      ),
    );
  }
}

class AccessorySlot extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const AccessorySlot({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
      ),
    );
  }
}