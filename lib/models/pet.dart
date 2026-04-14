import 'package:cloud_firestore/cloud_firestore.dart';
 
// ─────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────
 
/// The three available pet species, chosen once at account creation.
enum PetType { bunny, cat, deer }
 
/// Levels are derived from [Pet.totalCoinsEarned] — never stored separately
/// in Firestore. Because they use the lifetime earnings figure (not the
/// spendable balance), levels can never go backwards.
enum PetLevel { baby, kid, adult }
 
// ─────────────────────────────────────────────
// Constants — tune these numbers freely
// ─────────────────────────────────────────────
 
/// Total-coins-earned thresholds for each permanent level transition.
const int kLevelKidThreshold   = 100; // baby  → kid   (placeholder)
const int kLevelAdultThreshold = 300; // kid   → adult (placeholder)
 
/// Coins awarded when the player wins a game round.
const int kCoinsPerGameWin = 10;
 
/// Coins awarded at the end of a Pomodoro session.
const int kCoinsShortSession = 20; // 25–44 min session
const int kCoinsLongSession  = 40; // 45–60 min session
 
/// Bonus coins awarded when any stat reaches 100.
const int kStatFullBonus = 1;
 
/// How much energy is restored per minute of sleep.
const int kEnergyPerSleepMinute = 20;
 
// ─────────────────────────────────────────────
// Food items
// ─────────────────────────────────────────────
 
/// Represents one item in the food pantry.
/// [icon] is a placeholder — swap in your designer's asset paths once
/// they are ready (e.g. 'assets/food/apple.png').
class FoodItem {
  final String id;
  final String name;
  final String icon;       // placeholder: emoji string or asset path
  final int cost;          // paid in coins (spendable balance)
  final int hungerGain;
  final int happinessGain;
  final int energyGain;
 
  const FoodItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.cost,
    required this.hungerGain,
    required this.happinessGain,
    required this.energyGain,
  });
}
 
/// The five food options available in the pantry.
/// All costs and gains are placeholders — adjust freely.
/// When your designer finishes the food icons, replace the emoji
/// strings in [icon] with asset paths like 'assets/food/apple.png'.
const List<FoodItem> kFoodPantry = [
  FoodItem(
    id: 'apple',
    name: 'Apple',
    icon: '🍎',           // → replace with asset path later
    cost: 5,
    hungerGain: 20,
    happinessGain: 3,
    energyGain: 3,
  ),
  FoodItem(
    id: 'sandwich',
    name: 'Sandwich',
    icon: '🥪',
    cost: 10,
    hungerGain: 35,
    happinessGain: 5,
    energyGain: 5,
  ),
  FoodItem(
    id: 'pizza',
    name: 'Pizza',
    icon: '🍕',
    cost: 18,
    hungerGain: 50,
    happinessGain: 8,
    energyGain: 5,
  ),
  FoodItem(
    id: 'sushi',
    name: 'Sushi',
    icon: '🍣',
    cost: 25,
    hungerGain: 60,
    happinessGain: 10,
    energyGain: 8,
  ),
  FoodItem(
    id: 'cake',
    name: 'Cake',
    icon: '🎂',
    cost: 35,
    hungerGain: 70,
    happinessGain: 15,
    energyGain: 10,
  ),
];
 
// ─────────────────────────────────────────────
// Pet model
// ─────────────────────────────────────────────
 
class Pet {
  final String id;
  final String name;
  final PetType type;
 
  // Stats — always clamped to [0, 100].
  final int hunger;
  final int happiness;
  final int energy;
 
  // ── Currency ──────────────────────────────
  //
  // Two separate coin fields with different jobs:
  //
  //   coins              — the spendable balance shown in the UI coin button.
  //                        Goes up when coins are earned, down when spent.
  //
  //   totalCoinsEarned   — a lifetime counter that only ever increases.
  //                        Never decremented, even when the player spends coins.
  //                        Used exclusively for level calculation so levels
  //                        can never go backwards.
  //
  // Every earn operation increments BOTH fields.
  // Every spend operation decrements ONLY coins.
  //
  final int coins;
  final int totalCoinsEarned;
 
  // State
  final bool isAsleep;
 
  /// ID of the currently worn outfit/accessory, or null if none.
  /// When your designer finishes the wardrobe assets, this string
  /// will match the outfit IDs you define in your shop data.
  final String? outfit;
 
  /// Set when the pet falls asleep; cleared on wake.
  /// Used to calculate how much energy to restore.
  final DateTime? lastSleptAt;
 
  /// Used by DecayService to calculate stat decay while the app was closed.
  final DateTime lastUpdated;
 
  Pet({
    required this.id,
    required this.name,
    required this.type,
    required this.hunger,
    required this.happiness,
    required this.energy,
    required this.coins,
    required this.totalCoinsEarned,
    this.isAsleep = false,
    this.outfit,
    this.lastSleptAt,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
 
  // ── Computed getters ────────────────────────
 
  /// Derives the pet's permanent level from [totalCoinsEarned].
  /// Uses lifetime earnings so spending coins never lowers the level.
  /// Level is never stored in Firestore — it always stays in sync automatically.
  PetLevel get level {
    if (totalCoinsEarned >= kLevelAdultThreshold) return PetLevel.adult;
    if (totalCoinsEarned >= kLevelKidThreshold)   return PetLevel.kid;
    return PetLevel.baby;
  }
 
  /// Human-readable level label shown in the dashboard level button.
  String get levelName {
    switch (level) {
      case PetLevel.baby:  return 'Baby';
      case PetLevel.kid:   return 'Kid';
      case PetLevel.adult: return 'Adult';
    }
  }
 
  /// Asset path for the pet sprite.
  /// Convention: assets/pets/{type}/{level}.png
  ///
  /// Examples:
  ///   assets/pets/bunny/baby.png
  ///   assets/pets/cat/kid.png
  ///   assets/pets/deer/adult.png
  ///
  /// Tell your designer to save files using this exact naming convention
  /// and place them in the assets/pets/ folder. No code changes needed
  /// once the files are in the right place — the getter picks them up automatically.
  String get spriteAsset => 'assets/pets/${type.name}/${level.name}.png';
 
  // ── Immutable update ────────────────────────
 
  /// Returns a new [Pet] with only the specified fields changed.
  /// All stat and coin values are automatically clamped.
  ///
  /// Example — increase hunger by 30:
  ///   final updatedPet = pet.copyWith(hunger: pet.hunger + 30);
  ///
  /// IMPORTANT: when earning coins, always pass BOTH fields:
  ///   pet.copyWith(coins: pet.coins + 10, totalCoinsEarned: pet.totalCoinsEarned + 10)
  ///
  /// When spending coins, pass ONLY coins (totalCoinsEarned must not change):
  ///   pet.copyWith(coins: pet.coins - 5)
  ///
  /// The activity methods below handle this automatically — you only need to
  /// think about it if you're calling copyWith directly elsewhere in the app.
  Pet copyWith({
    String? name,
    PetType? type,
    int? hunger,
    int? happiness,
    int? energy,
    int? coins,
    int? totalCoinsEarned,
    bool? isAsleep,
    Object? outfit      = _sentinel,
    Object? lastSleptAt = _sentinel,
    DateTime? lastUpdated,
  }) {
    return Pet(
      id:                id,
      name:              name              ?? this.name,
      type:              type              ?? this.type,
      hunger:            (hunger           ?? this.hunger).clamp(0, 100),
      happiness:         (happiness        ?? this.happiness).clamp(0, 100),
      energy:            (energy           ?? this.energy).clamp(0, 100),
      coins:             (coins            ?? this.coins).clamp(0, 999999),
      totalCoinsEarned:  (totalCoinsEarned ?? this.totalCoinsEarned).clamp(0, 999999),
      isAsleep:          isAsleep          ?? this.isAsleep,
      outfit:      outfit      == _sentinel ? this.outfit      : outfit      as String?,
      lastSleptAt: lastSleptAt == _sentinel ? this.lastSleptAt : lastSleptAt as DateTime?,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
 
  // ─────────────────────────────────────────────
  // Private earn/spend helpers
  // ─────────────────────────────────────────────
 
  // These two helpers are used internally by every activity method.
  // They enforce the rule that earning always updates both coin fields,
  // while spending only touches the spendable balance.
 
  /// Adds [amount] to both [coins] and [totalCoinsEarned].
  Pet _earn(int amount) => copyWith(
    coins:            coins           + amount,
    totalCoinsEarned: totalCoinsEarned + amount,
  );
 
  /// Subtracts [amount] from [coins] only. [totalCoinsEarned] is unchanged.
  Pet _spend(int amount) => copyWith(
    coins: coins - amount,
  );
 
  // ─────────────────────────────────────────────
  // Activity logic
  // ─────────────────────────────────────────────
 
  // ── Feed ────────────────────────────────────
 
  /// Spends coins to feed the pet with [food].
  /// Throws [InsufficientCoinsException] if the player can't afford it.
  /// Awards [kStatFullBonus] coins for any stat that crosses into 100.
  Pet applyFood(FoodItem food) {
    if (coins < food.cost) {
      throw InsufficientCoinsException(
        'Not enough coins to buy ${food.name}. '
        'Need ${food.cost}, have $coins.',
      );
    }
 
    final newHunger    = (hunger    + food.hungerGain).clamp(0, 100);
    final newHappiness = (happiness + food.happinessGain).clamp(0, 100);
    final newEnergy    = (energy    + food.energyGain).clamp(0, 100);
 
    // Stat-full bonus: only triggered when a stat crosses into 100,
    // not when it was already at 100 before feeding.
    int bonus = 0;
    if (newHunger    == 100 && hunger    < 100) bonus += kStatFullBonus;
    if (newHappiness == 100 && happiness < 100) bonus += kStatFullBonus;
    if (newEnergy    == 100 && energy    < 100) bonus += kStatFullBonus;
 
    // First spend the food cost, then earn any bonus.
    // Spending and earning are kept separate so totalCoinsEarned is
    // never reduced by the food purchase.
    Pet updated = copyWith(
      hunger:    newHunger,
      happiness: newHappiness,
      energy:    newEnergy,
    )._spend(food.cost);
 
    if (bonus > 0) updated = updated._earn(bonus);
    return updated;
  }
 
  // ── Games ───────────────────────────────────
 
  /// Call once per completed game round.
  /// Pass [won] = true to also award [kCoinsPerGameWin] coins.
  /// Each round increases happiness and slightly decreases energy and hunger.
  Pet applyGameRound({required bool won}) {
    final newHappiness = (happiness + 10).clamp(0, 100);
    final newEnergy    = (energy    - 10).clamp(0, 100);
    final newHunger    = (hunger    -  5).clamp(0, 100);
 
    int bonus = 0;
    if (newHappiness == 100 && happiness < 100) bonus += kStatFullBonus;
 
    final coinsEarned = (won ? kCoinsPerGameWin : 0) + bonus;
 
    Pet updated = copyWith(
      happiness: newHappiness,
      energy:    newEnergy,
      hunger:    newHunger,
    );
 
    if (coinsEarned > 0) updated = updated._earn(coinsEarned);
    return updated;
  }
 
  // ── Sleep ───────────────────────────────────
 
  /// Puts the pet to sleep and records the time it fell asleep.
  /// Throws [PetAlreadyAsleepException] if already asleep.
  Pet putToSleep() {
    if (isAsleep) throw PetAlreadyAsleepException('$name is already asleep.');
    return copyWith(
      isAsleep:    true,
      lastSleptAt: DateTime.now(),
    );
  }
 
  /// Wakes the pet up and restores energy based on how long it slept.
  /// Energy restored = minutes slept × [kEnergyPerSleepMinute], capped at 100.
  /// Awards [kStatFullBonus] coins if energy reaches 100.
  /// Throws [PetAlreadyAwakeException] if already awake.
  Pet wakeUp() {
    if (!isAsleep) throw PetAlreadyAwakeException('$name is already awake.');
 
    int energyGained = 0;
    if (lastSleptAt != null) {
      final minutesSlept = DateTime.now().difference(lastSleptAt!).inMinutes;
      energyGained = (minutesSlept * kEnergyPerSleepMinute).clamp(0, 100 - energy);
    }
 
    final newEnergy = (energy + energyGained).clamp(0, 100);
    final bonus     = (newEnergy == 100 && energy < 100) ? kStatFullBonus : 0;
 
    Pet updated = copyWith(
      isAsleep:    false,
      lastSleptAt: null,
      energy:      newEnergy,
    );
 
    if (bonus > 0) updated = updated._earn(bonus);
    return updated;
  }
 
  // ── Pomodoro ────────────────────────────────
 
  /// Awards coins at the end of a Pomodoro session.
  /// Sessions under 25 minutes give no reward.
  /// 25–44 min → [kCoinsShortSession] coins.
  /// 45–60 min → [kCoinsLongSession] coins.
  Pet applyPomodoroSession(int durationMinutes) {
    if (durationMinutes < 25) return this;
    final earned = durationMinutes >= 45 ? kCoinsLongSession : kCoinsShortSession;
    return _earn(earned);
  }
 
  // ── Wardrobe ────────────────────────────────
 
  /// Spends [cost] coins and equips [outfitId].
  /// The outfit list and individual costs live in your shop data —
  /// pass the correct cost in from ShopScreen/PetService.
  /// When your designer is done, outfit IDs should match asset filenames,
  /// e.g. 'crown' → assets/outfits/crown.png
  /// Throws [InsufficientCoinsException] if the player can't afford it.
  Pet buyAndWearOutfit(String outfitId, int cost) {
    if (coins < cost) {
      throw InsufficientCoinsException(
        'Not enough coins to buy this outfit. '
        'Need $cost, have $coins.',
      );
    }
    return _spend(cost).copyWith(outfit: outfitId);
  }
 
  /// Removes the currently worn outfit without any coin transaction.
  Pet removeOutfit() => copyWith(outfit: null);
 
  // ─────────────────────────────────────────────
  // Firestore serialisation
  // ─────────────────────────────────────────────
 
  factory Pet.fromMap(String id, Map<String, dynamic> data) {
    return Pet(
      id:                id,
      name:              data['name'] ?? 'Unknown',
      type:              _petTypeFromString(data['type']),
      hunger:            (data['hunger']           as num? ?? 100).toInt().clamp(0, 100),
      happiness:         (data['happiness']        as num? ?? 100).toInt().clamp(0, 100),
      energy:            (data['energy']           as num? ?? 100).toInt().clamp(0, 100),
      coins:             (data['coins']            as num? ??   0).toInt().clamp(0, 999999),
      totalCoinsEarned:  (data['totalCoinsEarned'] as num? ??   0).toInt().clamp(0, 999999),
      isAsleep:          data['isAsleep']          as bool? ?? false,
      outfit:            data['outfit']            as String?,
      lastSleptAt:       (data['lastSleptAt']  as Timestamp?)?.toDate(),
      lastUpdated:       (data['lastUpdated']  as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
 
  /// Produces the map written to Firestore.
  /// Do NOT include lastUpdated or lastSleptAt here —
  /// PetService writes those using FieldValue.serverTimestamp().
  Map<String, dynamic> toMap() {
    return {
      'name':             name,
      'type':             type.name,  // stored as 'bunny', 'cat', or 'deer'
      'hunger':           hunger,
      'happiness':        happiness,
      'energy':           energy,
      'coins':            coins,
      'totalCoinsEarned': totalCoinsEarned,
      'isAsleep':         isAsleep,
      'outfit':           outfit,
    };
  }
 
  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────
 
  static PetType _petTypeFromString(dynamic value) {
    switch (value) {
      case 'bunny': return PetType.bunny;
      case 'deer':  return PetType.deer;
      default:      return PetType.cat;
    }
  }
}
 
// Sentinel object used by copyWith so that passing outfit: null
// is distinguishable from not passing outfit at all.
const Object _sentinel = Object();
 
// ─────────────────────────────────────────────
// Domain exceptions
// ─────────────────────────────────────────────
 
class InsufficientCoinsException implements Exception {
  final String message;
  const InsufficientCoinsException(this.message);
  @override
  String toString() => 'InsufficientCoinsException: $message';
}
 
class PetAlreadyAsleepException implements Exception {
  final String message;
  const PetAlreadyAsleepException(this.message);
  @override
  String toString() => 'PetAlreadyAsleepException: $message';
}
 
class PetAlreadyAwakeException implements Exception {
  final String message;
  const PetAlreadyAwakeException(this.message);
  @override
  String toString() => 'PetAlreadyAwakeException: $message';
}