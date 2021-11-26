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
import 'package:odin/services/locator.dart';
import 'package:odin/services/preferences_service.dart';
import 'package:odin/services/toast_service.dart';
import 'package:odin/widgets/window_top_bar.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
  bool _qrVisible = false;
  final _toast = locator<ToastService>();
  final PreferencesService _preferencesService = locator<PreferencesService>();

  @override
  void initState() {
    _preferencesService.init();
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
    _toast.init(context);
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
            Center(
              child: CustomPaint(
                painter: RipplePainter(
                  color: Colors.white,
                  animationValue: animation.value,
                ),
                child: SizedBox(
                  width: (Platform.isWindows || Platform.isMacOS)
                      ? MediaQuery.of(context).size.width
                      : MediaQuery.of(context).size.width * 0.8,
                  height: (Platform.isWindows || Platform.isMacOS)
                      ? MediaQuery.of(context).size.height
                      : MediaQuery.of(context).size.height * 0.8,
                ),
              ),
            ),
            // Glow painter
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
                width: (Platform.isWindows || Platform.isMacOS)
                    ? MediaQuery.of(context).size.width / 4.8
                    : MediaQuery.of(context).size.width * 0.4,
                height: (Platform.isWindows || Platform.isMacOS)
                    ? MediaQuery.of(context).size.width / 4.8
                    : MediaQuery.of(context).size.width * 0.4,
              ),
            ),
            // Odin logo painter
            Align(
              alignment: Alignment.center,
              child: CustomPaint(
                size: (Platform.isWindows || Platform.isMacOS)
                    ? Size(
                        MediaQuery.of(context).size.width / 4.8,
                        (MediaQuery.of(context).size.width / 4.8 * 1)
                            .toDouble())
                    : Size(MediaQuery.of(context).size.width * 0.4,
                        (MediaQuery.of(context).size.width * 0.4).toDouble()),
                painter: _dragging || _hovering
                    ? DropIconCustomPainter()
                    : _fileNotifier.fileLink != null
                        ? DoneIconCustomPainter()
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
                    bottom: (Platform.isWindows || Platform.isMacOS)
                        ? glow
                            ? MediaQuery.of(context).size.width / 3
                            : MediaQuery.of(context).size.width / 3.2
                        : glow
                            ? MediaQuery.of(context).size.width / 1.6
                            : MediaQuery.of(context).size.width / 1.7),
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
                                : (Platform.isWindows || Platform.isMacOS)
                                    ? 'Drop files to start.'
                                    : 'Tap to share files.',
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
                          if (_fileNotifier.zipfileName == '')
                            Padding(
                              padding: const EdgeInsets.only(bottom: 24.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(500),
                                child: SizedBox(
                                  width: (Platform.isWindows ||
                                          Platform.isMacOS)
                                      ? MediaQuery.of(context).size.width * 0.25
                                      : MediaQuery.of(context).size.width * 0.4,
                                  child: LinearProgressIndicator(
                                    backgroundColor:
                                        Colors.white.withOpacity(0.1),
                                    color: Colors.white,
                                    minHeight: 2,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                              margin: const EdgeInsets.only(bottom: 24.0),
                              width: (Platform.isWindows || Platform.isMacOS)
                                  ? MediaQuery.of(context).size.width * 0.25
                                  : MediaQuery.of(context).size.width * 0.4,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white12,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _fileNotifier.zipfileName[0],
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: ((Platform.isWindows ||
                                                      Platform.isMacOS)
                                                  ? MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.25
                                                  : MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.4) -
                                              24 -
                                              38,
                                          child: Text(
                                            _fileNotifier.zipfileName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.normal,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(500),
                                          child: SizedBox(
                                            width: ((Platform.isWindows ||
                                                        Platform.isMacOS)
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.25
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width *
                                                        0.4) -
                                                24 -
                                                38,
                                            child: LinearProgressIndicator(
                                              backgroundColor:
                                                  Colors.white.withOpacity(0.1),
                                              color: Colors.white,
                                              minHeight: 3,
                                            ),
                                          ),
                                        ),
                                      ])
                                ],
                              ),
                            ),
                        if (_fileNotifier.fileLink != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => FlutterClipboard.copy(_fileNotifier
                                                .fileLink !=
                                            null
                                        ? "Some files were shared with you.\nTo access them, download Odin from https://shrtco.de/odin and enter this unique token - ${_fileNotifier.fileLink}"
                                        : '')
                                    .then((value) => _toast.showToast(
                                        Platform.isIOS || Platform.isMacOS
                                            ? CupertinoIcons.check_mark
                                            : Icons.check,
                                        "Token copied to clipboard.")),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 0.5,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 10, 10, 10),
                                  margin:
                                      const EdgeInsets.fromLTRB(16, 16, 8, 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _fileNotifier.fileLink.toString(),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w200,
                                          letterSpacing: 0.5,
                                          color: Colors.white.withOpacity(0.8),
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
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: _fileNotifier.fileLink != null
                                    ? () => setState(() {
                                          _qrVisible = !_qrVisible;
                                        })
                                    : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.05),
                                      width: 0.5,
                                    ),
                                  ),
                                  padding:
                                      const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  margin:
                                      const EdgeInsets.fromLTRB(8, 16, 16, 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 24.0,
                                        width: 24.0,
                                        child: Icon(
                                          Platform.isIOS || Platform.isMacOS
                                              ? CupertinoIcons.qrcode
                                              : Icons.qr_code,
                                          size: 16,
                                          color: Colors.white.withOpacity(0.8),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            _fileNotifier.fileLink != null
                                ? "Share this token with your friends to access the files."
                                : "Files are encrypted with AES-256 encryption and will be deleted after 15 hours.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: (Platform.isWindows || Platform.isMacOS)
                                  ? 10
                                  : 12,
                              fontWeight: FontWeight.normal,
                              letterSpacing: -0.1,
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
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
            // QR code
            if (_qrVisible && _fileNotifier.fileLink != null)
              GestureDetector(
                onTap: _fileNotifier.fileLink != null
                    ? () => setState(() {
                          _qrVisible = !_qrVisible;
                        })
                    : null,
                child: SizedBox.expand(
                  child: Container(
                    color: Colors.black38,
                  ),
                ),
              ),
            if (_qrVisible && _fileNotifier.fileLink != null)
              Align(
                alignment: Alignment.center,
                child: GestureDetector(
                  onTap: _fileNotifier.fileLink != null
                      ? () => setState(() {
                            _qrVisible = !_qrVisible;
                          })
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: glow ? 40 : 10,
                          color: glow
                              ? Colors.white.withOpacity(0.1)
                              : Colors.white.withOpacity(0.0),
                        )
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7D5DEC),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: const EdgeInsets.all(16),
                            padding: const EdgeInsets.all(8),
                            width: (Platform.isWindows || Platform.isMacOS)
                                ? MediaQuery.of(context).size.width / 2.4
                                : MediaQuery.of(context).size.width * 0.8,
                            height: (Platform.isWindows || Platform.isMacOS)
                                ? MediaQuery.of(context).size.width / 2.4
                                : MediaQuery.of(context).size.width * 0.8,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: QrImage(
                                // backgroundColor: Colors.white12,
                                foregroundColor: Colors.white,
                                data: _fileNotifier.fileLink!,
                                size: (Platform.isWindows || Platform.isMacOS)
                                    ? MediaQuery.of(context).size.width / 2.6
                                    : MediaQuery.of(context).size.width * 0.7,
                              ),
                            ),
                          ),
                          Text(
                            "Scan using the Odin app to access the files.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.normal,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                        ],
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
