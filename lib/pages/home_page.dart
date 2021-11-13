import 'package:flutter/material.dart';
import 'package:odin/widgets/window_top_bar.dart';

const backgroundStartColor = Color(0x55121212);
const backgroundEndColor = Color(0x55202020);

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [backgroundStartColor, backgroundEndColor],
            radius: 1.5,
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: const [
            SizedBox.expand(),
            WindowTopBar(),
          ],
        ),
      ),
    );
  }
}
