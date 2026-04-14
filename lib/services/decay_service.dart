import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import 'pet_service.dart';

class DecayService {
  final PetService _petService = PetService();

  // How much each stat drops per hour — adjust after playtesting
  static const double hungerDecayPerHour    = 67; // empty in ~90 min
  static const double happinessDecayPerHour = 50; // empty in ~2 hours
  static const double energyDecayPerHour    = 33; // empty in ~3 hours

  // Call this every time the app opens — calculates how much time has passed
  // and applies the right amount of decay to each stat.
  Future<void> applyDecay(Pet pet) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final now       = DateTime.now();
    final hoursAway = now.difference(pet.lastUpdated).inSeconds / 3600;

    // If less than a minute has passed, don't bother updating
    if (hoursAway < 0.016) return;

    final newHunger    = _calcHunger(pet.hunger, hoursAway);
    final newHappiness = _calcHappiness(pet.happiness, hoursAway);
    final newEnergy    = _calcEnergy(pet.energy, hoursAway, pet.isAsleep);

    await _petService.updatePetStats(userId, pet.id, {
      'hunger':      newHunger,
      'happiness':   newHappiness,
      'energy':      newEnergy,
      'lastUpdated': DateTime.now(),
    });
  }

  // Hunger always decays — pet gets hungrier over time
  int _calcHunger(int current, double hoursAway) =>
      (current - hungerDecayPerHour * hoursAway).round().clamp(0, 100);

  // Happiness decays when the pet is awake and ignored
  int _calcHappiness(int current, double hoursAway) =>
      (current - happinessDecayPerHour * hoursAway).round().clamp(0, 100);

  // Energy decays when awake, but slowly recovers when asleep
  int _calcEnergy(int current, double hoursAway, bool isAsleep) {
    if (isAsleep) {
      return (current + energyDecayPerHour * 2 * hoursAway).round().clamp(0, 100);
    }
    return (current - energyDecayPerHour * hoursAway).round().clamp(0, 100);
  }
}
