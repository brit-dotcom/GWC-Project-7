import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import 'pet_service.dart';

class DecayService {
  final PetService _petService = PetService();

  // How much each stat drops per hour
  // Adjust these values after playtesting with Janvi!
  static const double hungerDecayPerHour = 67;    // empty in ~90 min
  static const double happinessDecayPerHour = 50; // empty in ~2 hours
  static const double energyDecayPerHour = 33;    // empty in ~3 hours
  static const double healthDecayPerHour = 10;    // only drops when neglected

  // Call this every time the app opens — calculates how much
  // time has passed and applies the right amount of decay
  Future<void> applyDecay(Pet pet) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    // Calculate how many hours have passed since last session
    final now = DateTime.now();
    final hoursAway = now.difference(pet.lastUpdated).inSeconds / 3600;

    // If less than a minute has passed, don't bother updating
    if (hoursAway < 0.016) return;

    // Calculate new stat values after decay
    int newHunger = hunger(pet.hunger, hoursAway);
    int newHappiness = happiness(pet.happiness, hoursAway);
    int newEnergy = energy(pet.energy, hoursAway, pet.isAsleep);
    int newHealth = health(pet.health, newHunger, newHappiness, newEnergy, hoursAway);

    // Save the decayed stats back to Firestore
    await _petService.updatePetStats(userId, pet.id, {
      'hunger': newHunger,
      'happiness': newHappiness,
      'energy': newEnergy,
      'health': newHealth,
      // Always update lastUpdated so next session calculates correctly
      'lastUpdated': DateTime.now(),
    });
  }

  // Hunger always decays — pet gets hungrier over time
  int hunger(int current, double hoursAway) {
    final decayed = current - (hungerDecayPerHour * hoursAway);
    // clamp() keeps the value between 0 and 100
    return decayed.round().clamp(0, 100);
  }

  // Happiness decays when the pet is awake and ignored
  int happiness(int current, double hoursAway) {
    final decayed = current - (happinessDecayPerHour * hoursAway);
    return decayed.round().clamp(0, 100);
  }

  // Energy decays when awake, but slowly recovers when asleep
  int energy(int current, double hoursAway, bool isAsleep) {
    if (isAsleep) {
      // Pet recovers energy at double the decay rate while sleeping
      final recovered = current + (energyDecayPerHour * 2 * hoursAway);
      return recovered.round().clamp(0, 100);
    } else {
      final decayed = current - (energyDecayPerHour * hoursAway);
      return decayed.round().clamp(0, 100);
    }
  }

  // Health only drops if the pet is being neglected across
  // multiple stats — acts as a last warning before critical state
  int health(int current, int newHunger, int newHappiness, int newEnergy, double hoursAway) {
    // Count how many stats are in the danger zone (below 20)
    int neglectedStats = 0;
    if (newHunger < 20) neglectedStats++;
    if (newHappiness < 20) neglectedStats++;
    if (newEnergy < 20) neglectedStats++;

    if (neglectedStats >= 2) {
      // Health drops faster the more stats are neglected
      final decayed = current - (healthDecayPerHour * neglectedStats * hoursAway);
      return decayed.round().clamp(0, 100);
    }

    // Health doesn't change if pet is being taken care of
    return current;
  }
}