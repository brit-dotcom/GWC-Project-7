import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'signup_page.dart';

// ---------------------------------------------------------------------------
// Entry point — preloads sprites then shows the login UI
// ---------------------------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _SpriteLoaderState();
}

class _SpriteLoaderState extends State<LoginPage> {
  final List<ImageInfo?> _images = [];
  bool _ready = false;

  static const List<String> _assetPaths = [
    'assets/adult_b_wings.png',
    'assets/adult_cat_wings.png',
    'assets/adult_deer_wings.png',
    'assets/bb_b_wings.png',
    'assets/bb_cat_wings.png',
    'assets/bb_deer_wings.png',
    'assets/kid_b_wings.png',
    'assets/kid_cat_wings.png',
    'assets/kid_deer_wings.png',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_ready) _loadAll();
  }

  Future<void> _loadAll() async {
    final results = await Future.wait(
      _assetPaths.map((path) async {
        try {
          final provider = AssetImage(path);
          final stream =
              provider.resolve(createLocalImageConfiguration(context));
          final completer = Completer<ImageInfo?>();
          stream.addListener(ImageStreamListener(
            (info, _) {
              if (!completer.isCompleted) completer.complete(info);
            },
            onError: (_, __) {
              if (!completer.isCompleted) completer.complete(null);
            },
          ));
          return await completer.future;
        } catch (_) {
          return null;
        }
      }),
    );

    if (mounted) {
      setState(() {
        _images
          ..clear()
          ..addAll(results);
        _ready = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: Color.fromARGB(255, 235, 185, 201),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _LoginPageWithSprites(loadedImages: _images);
  }
}

// ---------------------------------------------------------------------------
// Login UI with animated sprites
// ---------------------------------------------------------------------------
class _LoginPageWithSprites extends StatefulWidget {
  final List<ImageInfo?> loadedImages;
  const _LoginPageWithSprites({required this.loadedImages});

  @override
  State<_LoginPageWithSprites> createState() => _LoginPageWithSpritesState();
}

class _LoginPageWithSpritesState extends State<_LoginPageWithSprites>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = AuthService();
  bool isLoading = false;

  late final AnimationController _animController;
  late final Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    try {
      await auth.signIn(
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
      backgroundColor: const Color.fromARGB(255, 235, 185, 201),
      body: Stack(
        children: [
          // Animated sprites along arc
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _progressAnimation,
              builder: (context, _) {
                return CustomPaint(
                  painter: ArcSpritePainter(
                    progress: _progressAnimation.value,
                    sprites: widget.loadedImages,
                  ),
                );
              },
            ),
          ),

          // Login UI
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pomodachi',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    shadows: const [
                      Shadow(color: Colors.black26, blurRadius: 6)
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  width: 300,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF97A13B).withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(blurRadius: 10, color: Colors.black12),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Login",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: emailController,
                        style: GoogleFonts.playfairDisplay(),
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: GoogleFonts.playfairDisplay(),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: passwordController,
                        style: GoogleFonts.playfairDisplay(),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: GoogleFonts.playfairDisplay(),
                          border: const OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromRGBO(224, 163, 187, 0.80),
                                foregroundColor: Colors.black,
                              ),
                              child: Text(
                                "Login",
                                style: GoogleFonts.playfairDisplay(),
                              ),
                            ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupPage()),
                        ),
                        child: Text(
                          "Don't have an account? Sign up",
                          style: GoogleFonts.playfairDisplay(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Arc path
// ---------------------------------------------------------------------------
Path _buildArcPath(Size size) {
  final path = Path();
  path.moveTo(-40, size.height * 0.55);
  path.cubicTo(
    size.width * 0.25, size.height * 0.00,
    size.width * 0.75, size.height * 0.00,
    size.width + 40, size.height * 0.40,
  );
  return path;
}

// ---------------------------------------------------------------------------
// CustomPainter — evenly divides the arc by sprite count for seamless looping
// ---------------------------------------------------------------------------
class ArcSpritePainter extends CustomPainter {
  final double progress;
  final List<ImageInfo?> sprites;

  const ArcSpritePainter({
    required this.progress,
    required this.sprites,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final validSprites = sprites.where((s) => s != null).toList();
    if (validSprites.isEmpty) return;

    final path = _buildArcPath(size);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;
    final count = validSprites.length;

    // Spacing is exactly 1/count so the last sprite's next position
    // is sprite[0]'s position — perfectly seamless
    final double spacing = 1.0 / count;

    for (int i = 0; i < count; i++) {
      final image = validSprites[i]!;

      final rawT = (progress + i * spacing) % 1.0;
      final distance = rawT * totalLength;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;

      const double spriteSize = 64.0;
      final src = Rect.fromLTWH(
        0, 0,
        image.image.width.toDouble(),
        image.image.height.toDouble(),
      );
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: spriteSize,
        height: spriteSize,
      );

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(-tangent.angle);
      canvas.drawImageRect(image.image, src, dst, Paint());
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(ArcSpritePainter old) => old.progress != progress;
}