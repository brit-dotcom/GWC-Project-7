import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  final Future<void> Function() onCoinsEarned;

  const GamesScreen({super.key, required this.onCoinsEarned});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Games')),
      body: const Center(child: Text('Games — coming soon!')),
    );
  }
}
