class Pet {
  final String id;
  final String name;
  final String type;
  final int hunger;
  final int happiness;
  final int energy;
  final int health;
  final bool isAsleep; // ← new

  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.health,
    this.isAsleep = false, // defaults to awake
  });

  factory Pet.fromMap(String id, Map<String, dynamic> data) {
    return Pet(
      id: id,
      name: data['name'] ?? 'Unknown',
      type: data['type'] ?? 'cat',
      hunger: data['hunger'] ?? 100,
      happiness: data['happiness'] ?? 100,
      energy: data['energy'] ?? 100,
      health: data['health'] ?? 100,
      isAsleep: data['isAsleep'] ?? false, // ← new
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
      'isAsleep': isAsleep, // ← new
    };
  }
}