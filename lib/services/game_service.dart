import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_auth/firebase_auth.dart';

class GameService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cooldown duration — 4 hours per game as agreed
  static const Duration cooldownDuration = Duration(hours: 4);

  // Shortcut to the user's game cooldown document
  DocumentReference _cooldownRef(String userId) =>
      _db.collection('users').doc(userId).collection('gameCooldowns').doc('cooldowns');

  // Check if a specific game is currently on cooldown
  // Returns true if the game CAN be played, false if still cooling down
  Future<bool> canPlayGame(String userId, String gameId) async {
    try {
      final doc = await _cooldownRef(userId).get();
      if (!doc.exists) return true; // no cooldown record = can play

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(gameId)) return true;

      // Check if 4 hours have passed since last play
      final lastPlayed = (data[gameId] as Timestamp).toDate();
      final elapsed = DateTime.now().difference(lastPlayed);
      return elapsed >= cooldownDuration;
    } catch (e) {
      // If anything goes wrong, allow the game to be played
      return true;
    }
  }

  // Record that a game was just played — starts the 4 hour cooldown
  Future<void> recordGamePlayed(String userId, String gameId) async {
    await _cooldownRef(userId).set(
      {gameId: FieldValue.serverTimestamp()},
      // merge: true so we don't overwrite other games' cooldowns
      SetOptions(merge: true),
    );
  }

  // Returns how much time is left on a cooldown as a readable string
  // e.g. "3h 42m" or "Ready!" if cooldown is over
  Future<String> getCooldownText(String userId, String gameId) async {
    try {
      final doc = await _cooldownRef(userId).get();
      if (!doc.exists) return 'Ready!';

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey(gameId)) return 'Ready!';

      final lastPlayed = (data[gameId] as Timestamp).toDate();
      final elapsed = DateTime.now().difference(lastPlayed);
      final remaining = cooldownDuration - elapsed;

      if (remaining.isNegative) return 'Ready!';

      // Format as "Xh Ym"
      final hours = remaining.inHours;
      final minutes = remaining.inMinutes.remainder(60);
      if (hours > 0) return '${hours}h ${minutes}m';
      return '${minutes}m';
    } catch (e) {
      return 'Ready!';
    }
  }
}