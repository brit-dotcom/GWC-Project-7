import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
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
  // Tracks which tab is currently selected (0=Home, 1=Shop, 2=Games, 3=Study)
  int currentIndex = 0;

  final petService = PetService();
  Pet? pet;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Load pet once when the app opens — all screens share this pet data
    loadPet();
  }

  Future<void> loadPet() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final fetchedPet = await petService.getPet(userId);
    setState(() {
      pet = fetchedPet;
      isLoading = false;
    });
  }

  // Called by any screen that changes pet stats, so the home
  // screen always shows fresh data without a full reload
  Future<void> refreshPet() async {
    await loadPet();
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

    // The four screens — passing pet + refreshPet so they can
    // read stats and trigger a refresh after any changes
    final screens = [
      PetScreen(pet: pet!, onAction: refreshPet),
      ShopScreen(pet: pet!, onPurchase: refreshPet),
      GamesScreen(onCoinsEarned: refreshPet),
      StudyScreen(onSessionComplete: refreshPet),
    ];

    return Scaffold(
      // Show whichever screen matches the selected tab
      body: screens[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => setState(() => currentIndex = index),
        // Needed so all 4 labels show — default only shows 3
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