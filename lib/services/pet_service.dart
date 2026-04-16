import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pet.dart';

class PetService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Shortcut to get the pets subcollection for a user
  CollectionReference _petsRef(String userId) =>
      _db.collection('users').doc(userId).collection('pets');

  // Create a brand new pet
  Future<void> createPet(String userId, String name, String type) async {
    await _petsRef(userId).add({
      'name':             name,
      'type':             type,
      'hunger':           80,
      'happiness':        70,
      'energy':           60,
      'coins':            0,
      'totalCoinsEarned': 0,
      'isAsleep':         false,
      'isHatched':        false,
      'lastUpdated':      FieldValue.serverTimestamp(),
      'createdAt':        FieldValue.serverTimestamp(),
    });
  }

  // Read the user's pet (returns first pet found)
  Future<Pet?> getPet(String userId) async {
    final snapshot = await _petsRef(userId).limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Pet.fromMap(doc.id, doc.data() as Map<String, dynamic>);
  }

  // Save a full Pet object to Firestore.
  // Use this after any Pet model method (applyFood, wakeUp, applyGameRound, etc.)
  Future<void> savePet(String userId, Pet pet) async {
    await _petsRef(userId).doc(pet.id).update({
      ...pet.toMap(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastSleptAt': pet.lastSleptAt != null
          ? Timestamp.fromDate(pet.lastSleptAt!)
          : null,
    });
  }

  // Update specific stats — used by DecayService
  Future<void> updatePetStats(
      String userId, String petId, Map<String, dynamic> stats) async {
    await _petsRef(userId).doc(petId).update({
      ...stats,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Put the pet to sleep — records the timestamp so wakeUp can calculate
  // how much energy to restore later
  Future<void> putToSleep(String userId, String petId) async {
    await _petsRef(userId).doc(petId).update({
      'isAsleep':    true,
      'lastSleptAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  // Wake the pet up — reads current state, applies energy restoration based
  // on how long the pet slept, then saves the result
  Future<void> wakeUp(String userId, String petId) async {
    final pet = await getPet(userId);
    if (pet == null || !pet.isAsleep) return;
    final updatedPet = pet.wakeUp(); // calculates energy from lastSleptAt
    await savePet(userId, updatedPet);
  }

  // Mark the pet as hatched after the egg-tap sequence completes
  Future<void> markPetHatched(String userId, String petId) async {
    await _petsRef(userId).doc(petId).update({'isHatched': true});
  }

  // Award coins after a game round — uses pet model's applyGameRound()
  // which handles happiness/energy/hunger effects too
  Future<void> applyGameRound(String userId, {required bool won}) async {
    final pet = await getPet(userId);
    if (pet == null) return;
    final updatedPet = pet.applyGameRound(won: won);
    await savePet(userId, updatedPet);
  }
  
}
