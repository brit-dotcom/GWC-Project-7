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
}