import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Shortcut to get the pets subcollection for a user
  CollectionReference _petsRef(String userId) {
    return _db.collection('users').doc(userId).collection('pets');
  }

  // Create a brand new pet
  Future<void> createPet(String userId, String name, String type) async {
    await _petsRef(userId).add({
      'name': name,
      'type': type,
      'hunger': 80,
      'happiness': 70,
      'energy': 60,
      'health': 100,
      'isAsleep': false,
      'lastUpdated': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Read the user's pet (returns first pet found)
  Future<Pet?> getPet(String userId) async {
    final snapshot = await _petsRef(userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Update specific stats (only overwrites fields you pass in)
  Future<void> updatePetStats(String userId, String petId, Map<String, dynamic> stats) async {
    await _petsRef(userId).doc(petId).update({
      ...stats,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Feed the pet — restores hunger by 30, capped at 100
  Future<void> feedPet(String userId, String petId, int currentHunger) async {
    final newHunger = (currentHunger + 30).clamp(0, 100);
    await updatePetStats(userId, petId, {'hunger': newHunger});
  }

  // Play with the pet — happiness +25, energy -10
  Future<void> playWithPet(String userId, String petId, int currentHappiness, int currentEnergy) async {
    final newHappiness = (currentHappiness + 25).clamp(0, 100);
    final newEnergy = (currentEnergy - 10).clamp(0, 100);
    await updatePetStats(userId, petId, {
      'happiness': newHappiness,
      'energy': newEnergy,
    });
  }

  // Put the pet to sleep — energy recovers via decay service while asleep
  Future<void> putToSleep(String userId, String petId) async {
    await updatePetStats(userId, petId, {'isAsleep': true});
  }

  // Wake the pet up
  Future<void> wakeUp(String userId, String petId) async {
    await updatePetStats(userId, petId, {'isAsleep': false});
  }

  // Add coins to the user's total — called when study session completes
  Future<void> addCoins(String userId, int amount) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final currentCoins = userDoc.data()?['coins'] ?? 0;
    final newCoins = currentCoins + amount;
    await _db.collection('users').doc(userId).update({'coins': newCoins});
  }

  // Read the user's current coin balance
  Future<int> getCoins(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    return userDoc.data()?['coins'] ?? 0;
  }

  // Spend coins — used by shop later
  // Returns true if purchase succeeded, false if not enough coins
  Future<bool> spendCoins(String userId, int amount) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final currentCoins = userDoc.data()?['coins'] ?? 0;
    if (currentCoins < amount) return false;
    await _db.collection('users').doc(userId).update({
      'coins': currentCoins - amount,
    });
    return true;
  }

} // ← all functions must be above this closing brace