import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import '../services/pet_service.dart';
import '../services/decay_service.dart';
import 'pet_screen.dart';
import 'games_screen.dart';
import 'study_screen.dart';
import 'pantry_screen.dart';    // replaces shop_screen.dart
import 'wardrobe_screen.dart';  // new screen
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  final petService   = PetService();
  final decayService = DecayService();
 
  Pet? pet;
  bool isLoading = true;
 
  @override
  void initState() {
    super.initState();
    loadPetWithDecay();
  }
 
  // Loads the pet then applies any time-based stat decay before showing the UI.
  Future<void> loadPetWithDecay() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fetchedPet = await petService.getPet(userId);
 
    if (fetchedPet != null) {
      await decayService.applyDecay(fetchedPet);
      final updatedPet = await petService.getPet(userId);
      setState(() {
        pet = updatedPet;
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }
 
  // Called by PetScreen and every sub-screen after any action that changes
  // the pet, so the UI always shows up-to-date stats and coins.
  Future<void> refreshPet() async {
    final userId     = FirebaseAuth.instance.currentUser!.uid;
    final updatedPet = await petService.getPet(userId);
    setState(() => pet = updatedPet);
  }
 
  // ── Navigation helpers ───────────────────────
 
  Future<void> _openGames() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamesScreen(onCoinsEarned: refreshPet),
      ),
    );
    await refreshPet();
  }
 
  Future<void> _openPomodoro() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        // pet is now passed in so StudyScreen can show the sprite.
        builder: (_) => StudyScreen(
          pet: pet!,
          onSessionComplete: refreshPet,
        ),
      ),
    );
    await refreshPet();
  }
 
  Future<void> _openPantry() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantryScreen(pet: pet!, onPurchase: refreshPet),
      ),
    );
    await refreshPet();
  }
 
  Future<void> _openWardrobe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WardrobeScreen(pet: pet!, onPurchase: refreshPet),
      ),
    );
    await refreshPet();
  }
 
  // ── Build ────────────────────────────────────
 
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
 
    return Scaffold(
      // The PetScreen owns the full visual layout of the main screen.
      // HomePage just wraps it and handles navigation to sub-screens.
      body: PetScreen(
        pet: pet!,
        onAction:       refreshPet,
        onOpenGames:    _openGames,
        onOpenPomodoro: _openPomodoro,
        onOpenPantry:   _openPantry,
        onOpenWardrobe: _openWardrobe,
      ),
    );
  }
}
 