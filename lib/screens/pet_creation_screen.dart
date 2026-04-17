import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/pet_service.dart';
import 'home_page.dart';

class PetCreationScreen extends StatefulWidget {
  const PetCreationScreen({super.key});

  @override
  State<PetCreationScreen> createState() => _PetCreationScreenState();
}

class _PetCreationScreenState extends State<PetCreationScreen> {
  // Controls the pet name text field
  final nameController = TextEditingController();

  // Our pet service for talking to Firestore
  final petService = PetService();

  // Default pet type selected when screen loads
  String selectedType = 'cat';

  // Controls whether the loading spinner shows
  bool isLoading = false;

  // All available pet types
  final List<String> petTypes = ['cat', 'bunny', 'deer'];

  @override
  void dispose() {
    // Always clean up controllers to avoid memory leaks
    nameController.dispose();
    super.dispose();
  }

  Future<void> handleCreatePet() async {
    // Don't let the user submit without a name
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give your pet a name!')),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      await petService.createPet(
        userId,
        nameController.text.trim(),
        selectedType,
      );

      // Navigate to home page — pushReplacement means the user
      // can't press back and end up on this screen again
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(204, 252, 206, 238), Color.fromRGBO(224, 163, 187, 0.80)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Create Your Pet',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Choose your companion!',
                  style: TextStyle(fontSize: 25, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // Placeholder pet icon — swap for real sprite later
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Center(
                    child: Text('🐾', style: TextStyle(fontSize: 72)),
                  ),
                ),

                const SizedBox(height: 32),

                // Pet name input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Pet Name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose a type:',
                    style: TextStyle(fontSize: 25, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 30),

                // Pet type selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: petTypes.map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => selectedType = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF97A13B)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF97A13B)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize:20,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const Spacer(),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : handleCreatePet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF97A13B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Meet my pet!',
                            style: TextStyle(fontSize: 35),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
