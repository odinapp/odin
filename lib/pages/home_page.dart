import 'package:flutter/material.dart';
import 'package:odin/constants/colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor _color = OColor.withContext(context);
    return Scaffold(
      backgroundColor: _color.primary,
    );
  }
}
