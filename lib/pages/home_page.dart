import 'dart:io';

import 'package:clipboard/clipboard.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/painters/done_icon_painter.dart';
import 'package:odin/painters/drop_icon_painter.dart';
import 'package:odin/painters/odin_logo_painter.dart';
import 'package:odin/painters/ripple_painter.dart';
import 'package:odin/painters/tooltip_painter.dart';
import 'package:odin/providers/file_notifier.dart';
import 'package:odin/widgets/window_top_bar.dart';
import 'package:provider/provider.dart';

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
  bool _hovering = false;
  bool glow = true;

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
          if (controller.value >= 0.7) {
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
    final _fileNotifier = context.watch<FileNotifier>();
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
                painter: _fileNotifier.fileLink != null
                    ? DoneIconCustomPainter()
                    : _dragging || _hovering
                        ? DropIconCustomPainter()
                        : OdinLogoCustomPainter(),
              ),
            ),
            // Tooltip painter
            Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.elasticOut,
                margin: EdgeInsets.only(
                    bottom: glow
                        ? MediaQuery.of(context).size.width / 3
                        : MediaQuery.of(context).size.width / 3.2),
                width: _fileNotifier.processing
                    ? 160
                    : _fileNotifier.loading
                        ? 160
                        : 220,
                height: 55,
                child: CustomPaint(
                  size: Size(220, (55 * 1).toDouble()),
                  painter: TooltipCustomPainter(),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        _fileNotifier.processing
                            ? "Processing."
                            : _fileNotifier.loading
                                ? "Uploading."
                                : 'Drop files to start.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF7D5DEC),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Drag & drop target
            DropTarget(
              onDragDone: (detail) async {
                await _fileNotifier.getLinkFromDroppedFiles(detail.urls);
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
                onTap: _fileNotifier.fileLink != null
                    ? () => FlutterClipboard.copy(_fileNotifier.fileLink ?? '')
                    : () async {
                        await _fileNotifier.getLinkFromFilePicker();
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
                          if (_fileNotifier.loading)
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
                          if (_fileNotifier.fileLink != null)
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
                                    _fileNotifier.fileLink.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w200,
                                      letterSpacing: 0.5,
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
                            "Files are encrypted with AES-256 encryption and will be deleted after 15 hours.",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width / 4.8,
                height: MediaQuery.of(context).size.width / 4.8,
                child: MouseRegion(
                  onEnter: (event) {
                    setState(() {
                      _hovering = true;
                    });
                  },
                  onExit: (event) {
                    setState(() {
                      _hovering = false;
                    });
                  },
                  cursor: SystemMouseCursors.click,
                  child: Align(
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () async {
                        await _fileNotifier.getLinkFromFilePicker();
                      },
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
