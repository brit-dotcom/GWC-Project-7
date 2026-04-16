import 'package:firebase_auth/firebase_auth.dart';
import '../models/pet.dart';
import 'pet_service.dart';

class DecayService {
  final PetService _petService = PetService();

  // How much each stat drops per hour while awake
  // These match the rates we agreed on:
  //   hunger    → fully depletes in ~90 minutes
  //   happiness → fully depletes in ~2 hours
  //   energy    → fully depletes in ~3 hours
  static const double hungerDecayPerHour    = 67.0;
  static const double happinessDecayPerHour = 50.0;
  static const double energyDecayPerHour    = 33.0;

  // Call this on every app open — calculates time away and
  // applies the correct amount of decay before showing the UI
  Future<void> applyDecay(Pet pet) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final now = DateTime.now();

    // Calculate hours passed since last session
    var hoursAway = now.difference(pet.lastUpdated).inSeconds / 3600;

    // Safety cap — never apply more than 6 hours of decay at once
    // prevents a bad/missing timestamp from wiping all stats instantly
    hoursAway = hoursAway.clamp(0.0, 6.0);

    // If less than a minute has passed, skip — not worth updating
    if (hoursAway < 0.016) return;

    // Calculate decayed stats based on whether pet is asleep or awake
    final newHunger    = _decayHunger(pet.hunger, hoursAway);
    final newHappiness = _decayHappiness(pet.happiness, hoursAway);
    final newEnergy    = _decayEnergy(pet.energy, hoursAway, pet.isAsleep);

    // Only write to Firestore if something actually changed
    if (newHunger    == pet.hunger &&
        newHappiness == pet.happiness &&
        newEnergy    == pet.energy) return;

    // Use updatePetStats so only changed fields are overwritten
    // and lastUpdated is always refreshed
    await _petService.updatePetStats(userId, pet.id, {
      'hunger':    newHunger,
      'happiness': newHappiness,
      'energy':    newEnergy,
    });
  }

  // Hunger always decays regardless of sleep state —
  // pet gets hungrier even while sleeping
  int _decayHunger(int current, double hoursAway) {
    final decayed = current - (hungerDecayPerHour * hoursAway);
    return decayed.round().clamp(0, 100);
  }

  // Happiness decays while awake and ignored
  int _decayHappiness(int current, double hoursAway) {
    final decayed = current - (happinessDecayPerHour * hoursAway);
    return decayed.round().clamp(0, 100);
  }

  // Energy decays while awake — but note: actual sleep energy
  // restoration is now handled by pet.wakeUp() in pet.dart using
  // lastSleptAt, so we don't need to recover energy here anymore
  int _decayEnergy(int current, double hoursAway, bool isAsleep) {
    // If asleep, skip decay — wakeUp() handles energy restoration
    if (isAsleep) return current;
    final decayed = current - (energyDecayPerHour * hoursAway);
    return decayed.round().clamp(0, 100);
  }
}