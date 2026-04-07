import 'package:flutter/material.dart';

class StudyScreen extends StatelessWidget {
  // Called after a Pomodoro session completes so HomePage refreshes coins
  final Future<void> Function() onSessionComplete;

  const StudyScreen({super.key, required this.onSessionComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Timer')),
      body: const Center(child: Text('Study timer coming soon!')),
    );
  }
}