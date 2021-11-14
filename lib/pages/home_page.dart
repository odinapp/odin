import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:odin/services/data_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/widgets/window_top_bar.dart';
import 'package:url_launcher/url_launcher.dart';

const backgroundStartColor = Color(0x55121212);
const backgroundEndColor = Color(0x55202020);

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _dragging = false;
  bool _loading = false;
  String? _fileLink;
  final _ds = locator<DataService>();

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
              onDragDone: (detail) async {
                setState(() {
                  _loading = true;
                });
                if (detail.urls.isNotEmpty) {
                  _fileLink = await _ds.uploadFileAnonymous(
                      File(detail.urls.first.toFilePath()));
                }
                setState(() {
                  _loading = false;
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
                    child: _loading
                        ? CircularProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.3),
                          )
                        : GestureDetector(
                            onTap: _fileLink != null
                                ? () => launch(_fileLink ?? '')
                                : null,
                            child: _fileLink == null
                                ? Text(
                                    'Drop a file to start',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w100,
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  )
                                : SelectableText(
                                    _fileLink.toString(),
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
            ),
            const WindowTopBar(),
          ],
        ),
      ),
    );
  }
}
