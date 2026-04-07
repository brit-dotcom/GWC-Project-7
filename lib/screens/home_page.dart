import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import '../services/decay_service.dart'; // ← new import
import '../models/pet.dart';
import 'pet_screen.dart';
import 'shop_screen.dart';
import 'games_screen.dart';
import 'study_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  final petService = PetService();
  final decayService = DecayService(); // ← new
  Pet? pet;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadPetWithDecay(); // ← changed from loadPet()
  }

  // Loads the pet then immediately applies any time decay
  // before showing the screen — so stats are always current
  Future<void> loadPetWithDecay() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Step 1: fetch the pet from Firestore
    final fetchedPet = await petService.getPet(userId);

    if (fetchedPet != null) {
      // Step 2: calculate and apply decay based on time away
      await decayService.applyDecay(fetchedPet);

      // Step 3: fetch again so UI shows the post-decay values
      final updatedPet = await petService.getPet(userId);
      setState(() {
        pet = updatedPet;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  // Refreshes pet data — called by child screens after any action
  Future<void> refreshPet() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final updatedPet = await petService.getPet(userId);
    setState(() => pet = updatedPet);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (pet == null) {
      return const Scaffold(
        body: Center(child: Text('No pet found.')),
      );
    }

    final screens = [
      PetScreen(pet: pet!, onAction: refreshPet),
      ShopScreen(pet: pet!, onPurchase: refreshPet),
      GamesScreen(onCoinsEarned: refreshPet),
      StudyScreen(onSessionComplete: refreshPet),
    ];

    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Shop'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(Icons.timer), label: 'Study'),
        ],
      ),
    );
  }
}