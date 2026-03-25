import 'package:auto_route/auto_route.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/dio_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/services/logger.dart';
import 'package:odin/utilities/debounce.dart';
import 'package:odin/utilities/networking.dart';
import 'package:odin/utilities/responsive.dart';
import 'package:provider/provider.dart';

part 'widgets/main_container.dart';
part 'widgets/back_button.dart';
part 'widgets/primary_button.dart';
part 'widgets/header_text.dart';
part 'widgets/info_text.dart';
part 'widgets/clickable_info_text.dart';
part 'widgets/success_body.dart';
part 'widgets/failure_body.dart';
part 'widgets/metadata_text.dart';

@RoutePage()
class DownloadPage extends StatefulWidget {
  const DownloadPage({Key? key}) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  Widget build(BuildContext context) {
    oApp.currentContext = context;
    final OColor color = OColor.withContext(context);

    return Scaffold(
      backgroundColor: color.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.background, color.backgroundContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: isMobileLayout(context)
            ? _MobileDownloadBody(color: color)
            : () {
                switch (Provider.of<DioNotifier>(context).apiStatus) {
                  case ApiStatus.init:
                  case ApiStatus.loading:
                    return const _Body();
                  case ApiStatus.failed:
                    return const _FailedBody();
                  case ApiStatus.success:
                    return const _SuccessBody();
                  default:
                }
              }(),
      ),
    );
  }
}

// ── Desktop bodies (unchanged) ───────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    return Center(child: MainContainer(color: color));
  }
}

class _FailedBody extends StatelessWidget {
  const _FailedBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final failure = Provider.of<DioNotifier>(context).fetchFilesMetadataFailure;
    return Center(
      child: FailedBody(color: color, fetchFilesMetadataFailure: failure!),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final success = Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess;
    return Center(
      child: SuccessBody(color: color, fetchFilesMetadataSuccess: success!),
    );
  }
}

// ── Mobile: single stateful body handles all states ─────────────────────────

class _MobileDownloadBody extends StatefulWidget {
  const _MobileDownloadBody({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  State<_MobileDownloadBody> createState() => _MobileDownloadBodyState();
}

class _MobileDownloadBodyState extends State<_MobileDownloadBody> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _token = '';
  final ODebounce _debounce = ODebounce(const Duration(milliseconds: 400));

  OColor get color => widget.color;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    // Reset stale status from a previous upload/download — deferred to avoid
    // calling notifyListeners() during an ongoing build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        locator<DioNotifier>().apiStatus = ApiStatus.init;
        locator<DioNotifier>().miniApiStatus = ApiStatus.init;
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    await locator<DioNotifier>().fetchFilesMetadata(_token, (c, t) {});
  }

  Future<void> _download() async {
    final dioService = locator<DioService>();
    final filePath = await dioService.getTempFilePath();
    await locator<DioNotifier>().downloadFile(_token, filePath, (c, t) {
      logger.d('Downloaded $c/$t');
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<DioNotifier>(context);
    final miniStatus = notifier.miniApiStatus;
    final apiStatus = notifier.apiStatus;

    // Download completed — show success screen
    if (apiStatus == ApiStatus.success) {
      return _MobileDownloadSuccess(color: color);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            IconButton(
              onPressed: () => locator<AppRouter>().pop(),
              icon: SvgPicture.asset(
                oImage.arrowLeft,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  color.secondaryOnBackground,
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(height: 32),
            Text(
              oApp.currentConfig?.token.title ?? 'Receive files',
              style: GoogleFonts.inter(
                color: color.secondary,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              oApp.currentConfig?.token.description ??
                  'Enter the 8-character token shared with you.',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Token input — 8-box OTP style
            _TokenBoxInput(
              color: color,
              controller: _controller,
              focusNode: _focusNode,
              miniStatus: miniStatus,
              onChanged: (value) {
                setState(() => _token = value);
                if (value.length >= 6) {
                  _debounce.call(_fetchMetadata);
                } else {
                  locator<DioNotifier>().miniApiStatus = ApiStatus.init;
                }
              },
            ),
            // Metadata / error hint
            if (miniStatus == ApiStatus.success) ...[
              const SizedBox(height: 10),
              _MobileMetadataHint(color: color),
            ] else if (miniStatus == ApiStatus.failed) ...[
              const SizedBox(height: 8),
              Text(
                _friendlyError(notifier.fetchFilesMetadataFailure?.message),
                style: GoogleFonts.inter(
                  color: color.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const Spacer(),
            // Download button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: miniStatus == ApiStatus.success ? _download : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: apiStatus == ApiStatus.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        oApp.currentConfig?.token.primaryButtonText ??
                            'Download files',
                        style: GoogleFonts.inter(
                          color: miniStatus == ApiStatus.success
                              ? Colors.white
                              : color.secondaryOnBackground,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _friendlyError(String? raw) {
    if (raw == null || raw.isEmpty) return 'Token not found or expired.';
    final lower = raw.toLowerCase();
    if (lower.contains('not found') || lower.contains('expired')) {
      return 'Token not found or expired. Check it and try again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'No internet connection. Check your network and try again.';
    }
    return raw;
  }
}

class _MobileMetadataHint extends StatelessWidget {
  const _MobileMetadataHint({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final metadata = Provider.of<DioNotifier>(
      context,
    ).fetchFilesMetadataSuccess?.filesMetadata;
    if (metadata == null) return const SizedBox.shrink();

    final fileCount = metadata.files?.length ?? 0;
    final totalSize = metadata.totalFileSize ?? '';
    final fileLabel = fileCount == 1 ? '1 file' : '$fileCount files';

    return Row(
      children: [
        Icon(Icons.check_circle_rounded, color: color.primary, size: 14),
        const SizedBox(width: 6),
        Text(
          '$fileLabel · $totalSize — ready to download',
          style: GoogleFonts.inter(
            color: color.primary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Mobile: Download success ─────────────────────────────────────────────────

class _MobileDownloadSuccess extends StatelessWidget {
  const _MobileDownloadSuccess({Key? key, required this.color})
    : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final file = Provider.of<DioNotifier>(context).downloadFileSuccess?.file;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            IconButton(
              onPressed: () => locator<AppRouter>().popUntilRoot(),
              icon: SvgPicture.asset(
                oImage.arrowLeft,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  color.secondaryOnBackground,
                  BlendMode.srcIn,
                ),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Spacer(),
            Center(child: Image.asset(oImage.success, width: 120, height: 120)),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Download complete!',
                style: GoogleFonts.inter(
                  color: color.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (file != null)
              Center(
                child: Text(
                  file.path.split('/').last,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: color.secondaryOnBackground,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => locator<AppRouter>().popUntilRoot(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Back to home',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Token box input ───────────────────────────────────────────────────────────

class _TokenBoxInput extends StatefulWidget {
  const _TokenBoxInput({
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.miniStatus,
    required this.onChanged,
  });

  final OColor color;
  final TextEditingController controller;
  final FocusNode focusNode;
  final ApiStatus? miniStatus;
  final ValueChanged<String> onChanged;

  @override
  State<_TokenBoxInput> createState() => _TokenBoxInputState();
}

class _TokenBoxInputState extends State<_TokenBoxInput>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnim;
  ApiStatus? _prevStatus;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _shakeAnim =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
  }

  @override
  void didUpdateWidget(_TokenBoxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.miniStatus == ApiStatus.failed &&
        _prevStatus != ApiStatus.failed) {
      _shakeController.forward(from: 0);
    }
    _prevStatus = widget.miniStatus;
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final isSuccess = widget.miniStatus == ApiStatus.success;
    final isFailed = widget.miniStatus == ApiStatus.failed;
    final isLoading = widget.miniStatus == ApiStatus.loading;

    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeAnim.value, 0),
        child: child,
      ),
      child: GestureDetector(
        onTap: () => widget.focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // Invisible text field — captures keyboard input
            SizedBox(
              height: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: widget.focusNode,
                textCapitalization: TextCapitalization.none,
                autocorrect: false,
                enableSuggestions: false,
                showCursor: false,
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                decoration: const InputDecoration.collapsed(hintText: ''),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(8),
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                ],
                onChanged: widget.onChanged,
              ),
            ),
            // 8 character boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(8, (i) {
                final hasChar = i < text.length;
                final isActive =
                    i == text.length && !isSuccess && !isFailed && !isLoading;

                final Color borderColor;
                if (isSuccess) {
                  borderColor = widget.color.primary;
                } else if (isFailed) {
                  borderColor = widget.color.error;
                } else if (isActive) {
                  borderColor = widget.color.primary.withOpacity(0.6);
                } else if (hasChar) {
                  borderColor = const Color(0xFF3A3A3A);
                } else {
                  borderColor = const Color(0xFF242424);
                }

                final Color bgColor = hasChar
                    ? isSuccess
                          ? widget.color.primary.withOpacity(0.08)
                          : const Color(0xFF1E1E1E)
                    : const Color(0xFF151515);

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  width: 36,
                  height: 54,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor,
                      width: isActive || isSuccess ? 1.5 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: hasChar
                      ? Text(
                          text[i].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: isSuccess
                                ? widget.color.primary
                                : widget.color.secondary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : isActive
                      ? _BlinkingCursor(color: widget.color.primary)
                      : isLoading && i < 8
                      ? null
                      : null,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor({required this.color});
  final Color color;

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 530),
    )..repeat(reverse: true);
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
      builder: (_, __) => Opacity(
        opacity: _controller.value > 0.5 ? 1.0 : 0.0,
        child: Container(
          width: 2,
          height: 22,
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
