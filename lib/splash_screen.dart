import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_gate.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<IconData> _floatingIcons = [
    Icons.auto_stories,
    Icons.edit_note,
    Icons.calculate,
    Icons.science,
    Icons.lightbulb_outline,
    Icons.school,
  ];

  @override
  void initState() {
    super.initState();

    // Pulse Animation for the Logo
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade and Slide Animation for Text
    _fadeController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..forward();

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
        );

    // Navigation Timer
    Timer(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: Duration(milliseconds: 800),
          pageBuilder: (_, __, ___) => AuthGate(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF004D40), // Deep Teal
                  Color(0xFF00695C),
                  Color(0xFF26A69A), // Lighter Teal
                ],
              ),
            ),
          ),

          // 2. Animated Floating Particles
          ...List.generate(15, (index) => _buildFloatingParticle(index)),

          // 3. Central Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          "KTU NOTES AI",
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(2, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Learn Smarter, Not Harder",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = Random(index);
    final size = 20.0 + random.nextInt(20);
    final icon = _floatingIcons[random.nextInt(_floatingIcons.length)];
    final left = random.nextDouble() * 400; // Approximate screen width
    final duration = 3 + random.nextInt(4); // 3-7 seconds

    return _FloatingParticle(
      icon: icon,
      size: size,
      left: left,
      duration: Duration(seconds: duration),
      delay: Duration(milliseconds: random.nextInt(2000)),
    );
  }
}

class _FloatingParticle extends StatefulWidget {
  final IconData icon;
  final double size;
  final double left;
  final Duration duration;
  final Duration delay;

  const _FloatingParticle({
    required this.icon,
    required this.size,
    required this.left,
    required this.duration,
    required this.delay,
  });

  @override
  __FloatingParticleState createState() => __FloatingParticleState();
}

class __FloatingParticleState extends State<_FloatingParticle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _positionAnimation = Tween<double>(
      begin: 1.1,
      end: -0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    _opacityAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.4), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.0), weight: 20),
    ]).animate(_controller);

    Future.delayed(widget.delay, () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        return Positioned(
          left: widget.left,
          top: _positionAnimation.value * screenHeight,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Icon(widget.icon, size: widget.size, color: Colors.white),
          ),
        );
      },
    );
  }
}
