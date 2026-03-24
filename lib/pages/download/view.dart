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
    return Center(child: FailedBody(color: color, fetchFilesMetadataFailure: failure!));
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final success = Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess;
    return Center(child: SuccessBody(color: color, fetchFilesMetadataSuccess: success!));
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
  String _token = '';
  ODebounce _debounce = ODebounce(const Duration(milliseconds: 300));

  OColor get color => widget.color;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // Reset any stale status left over from a previous upload/download
    locator<DioNotifier>().apiStatus = ApiStatus.init;
    locator<DioNotifier>().miniApiStatus = ApiStatus.init;
  }

  @override
  void dispose() {
    _controller.dispose();
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
                colorFilter: ColorFilter.mode(color.secondaryOnBackground, BlendMode.srcIn),
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
                  'Paste or type a token to download the shared files.',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            // Token input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: miniStatus == ApiStatus.success
                      ? color.primary
                      : miniStatus == ApiStatus.failed
                          ? color.error
                          : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: GoogleFonts.inter(
                        color: color.secondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: oApp.currentConfig?.token.textFieldHintText ?? 'Enter token',
                        hintStyle: GoogleFonts.inter(
                          color: color.secondaryOnBackground,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(200),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9:/.\-_~%?&=#@]'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _token = value);
                        if (value.length > 3) {
                          _debounce.call(_fetchMetadata);
                        } else {
                          locator<DioNotifier>().miniApiStatus = ApiStatus.init;
                        }
                      },
                    ),
                  ),
                  // Status indicator
                  if (miniStatus == ApiStatus.loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else if (miniStatus == ApiStatus.failed)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(Icons.close_rounded, color: color.error, size: 20),
                    )
                  else if (miniStatus == ApiStatus.success)
                    Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Icon(Icons.check_circle_rounded, color: color.primary, size: 20),
                    ),
                ],
              ),
            ),
            // Metadata hint
            if (miniStatus == ApiStatus.success) ...[
              const SizedBox(height: 8),
              _MobileMetadataHint(color: color),
            ] else if (miniStatus == ApiStatus.failed) ...[
              const SizedBox(height: 8),
              Text(
                notifier.fetchFilesMetadataFailure?.message ?? 'Token not found or expired',
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
                onPressed: miniStatus == ApiStatus.success && _token.length > 3
                    ? _download
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  disabledBackgroundColor: const Color(0xFF2A2A2A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        oApp.currentConfig?.token.primaryButtonText ?? 'Download',
                        style: GoogleFonts.inter(
                          color: miniStatus == ApiStatus.success ? Colors.white : color.secondaryOnBackground,
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

class _MobileMetadataHint extends StatelessWidget {
  const _MobileMetadataHint({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final metadata =
        Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess?.filesMetadata;
    if (metadata == null) return const SizedBox.shrink();

    final fileCount = metadata.files?.length ?? 0;
    final totalSize = metadata.totalFileSize ?? '';
    final label = fileCount == 1
        ? '1 file · $totalSize'
        : '$fileCount files · $totalSize';

    return Text(
      label,
      style: GoogleFonts.inter(
        color: color.primary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Mobile: Download success ─────────────────────────────────────────────────

class _MobileDownloadSuccess extends StatelessWidget {
  const _MobileDownloadSuccess({Key? key, required this.color}) : super(key: key);

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
                colorFilter: ColorFilter.mode(color.secondaryOnBackground, BlendMode.srcIn),
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Spacer(),
            Center(
              child: Image.asset(oImage.success, width: 120, height: 120),
            ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
