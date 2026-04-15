import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
//updated signup
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> handleSignup() async {
    setState(() => isLoading = true);
    try {
      await auth.signUp(
        emailController.text.trim(),
        passwordController.text,
      );
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
      backgroundColor: Color.fromARGB(255, 235, 185, 201),
      appBar: AppBar(
        title: Text(
          "Sign Up",
          style: GoogleFonts.playfairDisplay(),
        ),
        backgroundColor: Color.fromARGB(255, 235, 185, 201),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              style:GoogleFonts.playfairDisplay(),
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: GoogleFonts.playfairDisplay(),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              style:GoogleFonts.playfairDisplay(),
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: GoogleFonts.playfairDisplay(),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: handleSignup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF97A13B)),
              
                    child: Text(
                      "Sign Up",
                      style: GoogleFonts.playfairDisplay(),
                    ),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Already have an account? Log in",
                style: GoogleFonts.playfairDisplay(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}