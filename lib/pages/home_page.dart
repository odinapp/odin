import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:odin/painters/done_icon_painter.dart';
import 'package:odin/painters/drop_icon_painter.dart';
import 'package:odin/painters/odin_logo_painter.dart';
import 'package:odin/painters/ripple_painter.dart';
import 'package:odin/services/file_picker_service.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/zip_service.dart';
import 'package:odin/widgets/window_top_bar.dart';

const backgroundStartColor = Color(0xFF7D5DEC);
const backgroundEndColor = Color(0xFF6148B9);

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // Animation controller for ripple animation
  late Animation<double> animation;
  late AnimationController controller;
  final Tween<double> _sizeTween = Tween(begin: .4, end: 1);

  bool _dragging = false;
  bool _loading = false;
  bool glow = true;
  String? _fileLink;
  final _gs = locator<GithubService>();
  final _zs = locator<ZipService>();
  final _fps = locator<FilepickerService>();

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    animation = _sizeTween.animate(
      CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ),
    )..addListener(() {
        setState(() {
          if (controller.value >= 0.9) {
            glow = false;
          } else if (controller.value <= 0.1) {
            glow = true;
          }
        });
      });
    // Starting ripple animation
    controller.repeat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF7D5DEC),
      body: Container(
        // Gradient background
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [backgroundStartColor, backgroundEndColor],
            radius: 2,
            center: Alignment.topLeft,
            stops: [0.0, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ripple animation painter
            CustomPaint(
              painter: RipplePainter(
                color: Colors.white,
                animationValue: animation.value,
              ),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: glow ? 40 : 10,
                        color: glow
                            ? Colors.white.withOpacity(0.5)
                            : Colors.white.withOpacity(0.2),
                      )
                    ]),
                width: MediaQuery.of(context).size.width / 4.8,
                height: MediaQuery.of(context).size.width / 4.8,
              ),
            ),
            // Odin logo painter
            Align(
              alignment: Alignment.center,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width / 4.8,
                    (MediaQuery.of(context).size.width / 4.8 * 1).toDouble()),
                painter: _fileLink != null
                    ? DoneIconCustomPainter()
                    : _dragging
                        ? DropIconCustomPainter()
                        : OdinLogoCustomPainter(),
              ),
            ),
            // Drag & drop target
            DropTarget(
              onDragDone: (detail) async {
                setState(() {
                  _loading = true;
                });
                if (detail.urls.isNotEmpty) {
                  final int length = detail.urls.length;
                  if (length > 1) {
                    final List<File> fileToZips =
                        detail.urls.map((e) => File(e.toFilePath())).toList();
                    final zippedFile =
                        await _zs.zipFile(fileToZips: fileToZips);
                    _fileLink = await _gs.uploadFileAnonymous(zippedFile);
                  } else {
                    _fileLink = await _gs.uploadFileAnonymous(
                        File(detail.urls.first.toFilePath()));
                  }
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
              child: GestureDetector(
                onTap: _fileLink != null
                    ? () => FlutterClipboard.copy(_fileLink ?? '')
                    : () async {
                        setState(() {
                          _loading = true;
                        });
                        final linkFile = await _fps.getFiles();
                        setState(() {
                          _fileLink = linkFile;
                          _loading = false;
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Spacer(flex: 9),
                          if (_loading)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(500),
                                child: SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.25,
                                  child: LinearProgressIndicator(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    color: Colors.white,
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                            ),
                          if (_fileLink != null)
                            Container(
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6)),
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              margin: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SelectableText(
                                    _fileLink.toString(),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w300,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 4,
                                  ),
                                  SizedBox(
                                    height: 24.0,
                                    width: 24.0,
                                    child: Icon(
                                      Platform.isIOS || Platform.isMacOS
                                          ? CupertinoIcons.square_on_square
                                          : Icons.copy,
                                      size: 16,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          Text(
                            "Files are saved  in an anonymous GitHub Repo, and will be deleted after 15 hours.",
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.black.withOpacity(0.2)),
                          ),
                          const Spacer(flex: 1),
                        ],
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
