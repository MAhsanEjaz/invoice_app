import 'package:flutter/material.dart';

class AnimationScreen extends StatefulWidget {
  const AnimationScreen({super.key});

  @override
  State<AnimationScreen> createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen> {
  // Define initial and target positions
  bool _isMoved = false;

  @override
  void initState() {
    super.initState();

    // Delay before starting animation
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isMoved = true;
      });
    });
  }

  double top = 20;
  double left = 20;

  List<String> data = [];

  @override
  Widget build(BuildContext context) {
    // Screen size for centering
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(title: Text("Animated Move")),
      body: SafeArea(
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: Duration(seconds: 1),
              curve: Curves.easeInOut,
              top: _isMoved ? top : (size.height / 2) - 50,
              left: _isMoved ? left : (size.width / 2) - 50,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    left += details.delta.dx;
                    top += details.delta.dy;
                  });
                },
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                  alignment: Alignment.center,
                  child: Text("Box", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              top: _isMoved ? 20 : (size.height / 2) - 50,
              right: _isMoved ? 20 : (size.width / 2) - 50,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.red,
                alignment: Alignment.center,
                child: Text("Box", style: TextStyle(color: Colors.white)),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              bottom: _isMoved ? 20 : (size.height / 2) - 50,
              right: _isMoved ? 20 : (size.width / 2) - 50,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.pink,
                alignment: Alignment.center,
                child: Text("Box", style: TextStyle(color: Colors.white)),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(seconds: 2),
              curve: Curves.easeInOut,
              bottom: _isMoved ? 20 : (size.height / 2) - 50,
              left: _isMoved ? 20 : (size.width / 2) - 50,
              child: Container(
                width: 100,
                height: 100,
                color: Colors.yellow,
                alignment: Alignment.center,
                child: Text("Box", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
