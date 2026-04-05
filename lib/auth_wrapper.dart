import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/pet_creation_screen.dart';
import 'services/pet_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listens for login/logout events in real time
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        if (snapshot.hasData) {
          // User is logged in — now check if they have a pet
          return FutureBuilder(
            // Look up their pet in Firestore using their user ID
            future: PetService().getPet(snapshot.data!.uid),
            builder: (context, petSnapshot) {

              // Still waiting for Firestore to respond
              if (petSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Pet exists → go to home screen
              // No pet yet → go to pet creation screen
              if (petSnapshot.data != null) {
                return const HomePage();
              } else {
                return const PetCreationScreen();
              }
            },
          );
        } else {
          // User is not logged in → show login page
          return const LoginPage();
        }
      },
    );
  }
}