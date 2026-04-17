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
    {'image': 'assets/hat.jpg', 'label': 'Hat'},
    {'image': 'assets/earring.jpg', 'label': 'Earrings'},
    {'image': 'assets/tiara.jpg', 'label': 'Tiara'},
    {'image': 'assets/beanie.jpg', 'label': 'Beanie'},
    {'image': 'assets/ring.jpg', 'label': 'Ring'},
    {'image': 'assets/glasses.jpg', 'label': 'Glasses'},
    {'image': 'assets/wand.jpg', 'label': 'Wand'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wardrobe'),
        backgroundColor: const Color.fromARGB(255, 235, 185, 201),
      ),
      body: Stack(
        children: [
          // ── Background image ──────────────────
          Image.asset(
            'assets/newPixelWardrobe.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // ── Grid content ──────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wardrobeItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final accessory = _wardrobeItems[index];
                return AccessorySlot(
                  imagePath: accessory['image'] as String,
                  label: accessory['label'] as String,
                  onTap: () async {
                    await onPurchase();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AccessorySlot extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const AccessorySlot({
    super.key,
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            // ── Emoji (takes most space) ─────────
            Expanded(
              flex: 3,
              child: Center(
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── Label ───────────────────────────
            Expanded(
              flex: 1,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}