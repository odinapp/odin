import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:odin/widgets/window_top_bar.dart';

const backgroundStartColor = Color(0x55121212);
const backgroundEndColor = Color(0x55202020);

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Uri> _list = [];
  bool _dragging = false;

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
          children: [
            DropTarget(
              onDragDone: (detail) {
                setState(() {
                  _list.addAll(detail.urls);
                });
              },
              onDragEntered: (detail) {
                setState(() {
                  _dragging = true;
                });
              },
              onDragExited: (detail) {
                setState(() {
                  _dragging = false;
                });
              },
              child: SizedBox.expand(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  color: _dragging
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.transparent,
                  child: Center(
                    child: Text(
                      _list.isEmpty ? 'Drop a file to start' : _list.join("\n"),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w100,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const WindowTopBar(),
          ],
        ),
      ),
    );
  }
}
