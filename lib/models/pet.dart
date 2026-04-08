import 'package:cloud_firestore/cloud_firestore.dart';

class Pet {
  final String id;
  final String name;
  final String type;
  final int hunger;
  final int happiness;
  final int energy;
  final int health;
  final bool isAsleep;
  final DateTime lastUpdated; // ← new

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.health,
    this.isAsleep = false,
    DateTime? lastUpdated,
    // If no lastUpdated exists, default to now
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory Pet.fromMap(String id, Map<String, dynamic> data) {
    return Pet(
      id: id,
      name: data['name'] ?? 'Unknown',
      type: data['type'] ?? 'cat',
      hunger: data['hunger'] ?? 100,
      happiness: data['happiness'] ?? 100,
      energy: data['energy'] ?? 100,
      health: data['health'] ?? 100,
      isAsleep: data['isAsleep'] ?? false,
      // Convert Firestore Timestamp to Dart DateTime
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'hunger': hunger,
      'happiness': happiness,
      'energy': energy,
      'health': health,
      'isAsleep': isAsleep,
      // Don't include lastUpdated here — always use
      // FieldValue.serverTimestamp() when writing to Firestore
    };
  }
}