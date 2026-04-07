import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  // Called after a game is won so HomePage refreshes coin count
  final Future<void> Function() onCoinsEarned;

  const GamesScreen({super.key, required this.onCoinsEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Games')),
      body: const Center(child: Text('Games coming soon!')),
    );
  }
}