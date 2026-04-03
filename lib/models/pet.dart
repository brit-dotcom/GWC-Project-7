class Pet {
  final String id;
  final String name;
  final String type;
  final int hunger;
  final int happiness;
  final int energy;
  final int health;

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.health,
  });

  // Converts Firestore document → Pet object
  factory Pet.fromMap(String id, Map<String, dynamic> data) {
    return Pet(
      id: id,
      name: data['name'] ?? 'Unknown',
      type: data['type'] ?? 'cat',
      hunger: data['hunger'] ?? 100,
      happiness: data['happiness'] ?? 100,
      energy: data['energy'] ?? 100,
      health: data['health'] ?? 100,
    );
  }

  // Converts Pet object → Firestore document
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'hunger': hunger,
      'happiness': happiness,
      'energy': energy,
      'health': health,
    };
  }
}