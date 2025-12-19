import 'package:flutter/material.dart';

class NoInternetScreen extends StatefulWidget {
  @override
  _NoInternetScreenState createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                FadeTransition(
                  opacity: Tween<double>(
                    begin: 1.0,
                    end: 0.0,
                  ).animate(_controller),
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 1.0,
                      end: 2.0,
                    ).animate(_controller),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.2),
                      ),
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 80,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              "No Connection",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Please check your internet settings\nand try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {}, // Connection listener will auto-dismiss
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: Text(
                "Waiting for Network...",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
