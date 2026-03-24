import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/utilities/byte_formatter.dart';
import 'package:odin/utilities/networking.dart';
import 'package:odin/utilities/responsive.dart';
import 'package:provider/provider.dart';

part 'widgets/main_container.dart';
part 'widgets/back_button.dart';
part 'widgets/cross_button.dart';
part 'widgets/header_text.dart';
part 'widgets/info_text.dart';
part 'widgets/progress_bar.dart';
part 'widgets/success_body.dart';
part 'widgets/failure_body.dart';

@RoutePage()
class UploadPage extends StatefulWidget {
  const UploadPage({
    Key? key,
    required this.uploadFiles,
  }) : super(key: key);

  final List<File> uploadFiles;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  @override
  void initState() {
    super.initState();
    _uploadFiles();
  }

  Future<void> _uploadFiles() async {
    final dioNotifier = locator<DioNotifier>();
    await dioNotifier.uploadFilesAnonymous(widget.uploadFiles, (count, total) {});
  }

  @override
  Widget build(BuildContext context) {
    oApp.currentContext = context;
    final OColor color = OColor.withContext(context);
    final mobile = isMobileLayout(context);

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
        child: () {
          switch (Provider.of<DioNotifier>(context).apiStatus) {
            case ApiStatus.init:
            case ApiStatus.loading:
              return mobile ? _MobileLoadingBody(color: color) : const _Body();
            case ApiStatus.failed:
              return mobile
                  ? _MobileFailedBody(color: color)
                  : const _FailedBody();
            case ApiStatus.success:
              return mobile
                  ? _MobileSuccessBody(color: color)
                  : const _SuccessBody();
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
    final failure = Provider.of<DioNotifier>(context).uploadFilesFailure;
    return Center(child: FailedBody(color: color, uploadFilesFailure: failure!));
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final success = Provider.of<DioNotifier>(context).uploadFilesSuccess;
    return Center(child: SuccessBody(color: color, uploadFilesSuccess: success!));
  }
}

// ── Mobile: Loading ──────────────────────────────────────────────────────────

class _MobileLoadingBody extends StatelessWidget {
  const _MobileLoadingBody({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<DioNotifier>(context);
    final fileName = notifier.selectedFiles.isNotEmpty
        ? (notifier.selectedFiles.length == 1
            ? notifier.selectedFiles.first.path.split('/').last
            : '${notifier.selectedFiles.first.path.split('/').last} + ${notifier.selectedFiles.length - 1} more')
        : '';
    final fileSize = notifier.selectedFiles.isNotEmpty
        ? formatBytes(notifier.selectedFilesSize, 0)
        : '';
    final progress = notifier.progress;
    final percent = notifier.progressPercentage;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Back / cancel row
            IconButton(
              onPressed: () {
                locator<DioNotifier>().cancelCurrentRequest();
                locator<AppRouter>().pop();
              },
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
            // Heading
            Text(
              oApp.currentConfig?.upload.title ?? 'Uploading...',
              style: GoogleFonts.inter(
                color: color.secondary,
                fontSize: 36,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            if (fileName.isNotEmpty)
              Text(
                fileName,
                style: GoogleFonts.inter(
                  color: color.secondaryOnBackground,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (fileSize.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                fileSize,
                style: GoogleFonts.inter(
                  color: color.secondaryOnBackground,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
            const Spacer(),
            // Description
            Text(
              oApp.currentConfig?.upload.description ??
                  'Protected with end-to-end AES-256 encryption.',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    color: const Color(0xFF2A2A2A),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    height: 6,
                    width: (MediaQuery.of(context).size.width - 48) * progress,
                    decoration: BoxDecoration(
                      color: color.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$percent%',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () {
                  locator<DioNotifier>().cancelCurrentRequest();
                  locator<AppRouter>().pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: color.secondaryOnBackground,
                  side: BorderSide(color: color.secondaryOnBackground.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  oApp.currentConfig?.upload.cancelDefaultText ?? 'Cancel',
                  style: GoogleFonts.inter(
                    color: color.secondaryOnBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

// ── Mobile: Success ──────────────────────────────────────────────────────────

class _MobileSuccessBody extends StatelessWidget {
  const _MobileSuccessBody({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final success = Provider.of<DioNotifier>(context).uploadFilesSuccess;
    final token = success?.token ?? '';
    final deleteToken = success?.deleteToken;

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
            const Spacer(),
            // Success illustration
            Center(
              child: Image.asset(
                oImage.success,
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Files uploaded!',
                style: GoogleFonts.inter(
                  color: color.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Share the token below to let others download.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: color.secondaryOnBackground,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            // Token box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF242424),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      token,
                      style: GoogleFonts.inter(
                        color: color.secondaryOnBackground,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Copied to clipboard',
                            style: GoogleFonts.inter(
                              color: color.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: color.cardOnBackground,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SvgPicture.asset(
                        oImage.copy,
                        width: 18,
                        height: 18,
                        colorFilter: ColorFilter.mode(color.primary, BlendMode.srcIn),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Copy button (large, primary)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Copied to clipboard',
                        style: GoogleFonts.inter(color: color.secondary, fontSize: 14),
                      ),
                      backgroundColor: color.cardOnBackground,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Copy token',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Back to home button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => locator<AppRouter>().popUntilRoot(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color.secondaryOnBackground,
                  side: BorderSide(color: color.secondaryOnBackground.withOpacity(0.2)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Back to home',
                  style: GoogleFonts.inter(
                    color: color.secondaryOnBackground,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (deleteToken != null) ...[
              const SizedBox(height: 20),
              const Divider(color: Color(0xFF2A2A2A), thickness: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: color.error, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Delete files',
                    style: GoogleFonts.inter(
                      color: color.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Save your delete link to remove files from the server before they auto-expire.',
                style: GoogleFonts.inter(
                  color: color.secondaryOnBackground,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.error.withOpacity(0.25), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        deleteToken,
                        style: GoogleFonts.inter(
                          color: color.secondaryOnBackground,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: deleteToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Delete link copied',
                              style: GoogleFonts.inter(color: color.secondary, fontSize: 14),
                            ),
                            backgroundColor: color.cardOnBackground,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.copy_rounded, color: color.error, size: 16),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () async {
                        final uri = Uri.tryParse(deleteToken);
                        if (uri != null && await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: color.error.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.open_in_new_rounded, color: color.error, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Mobile: Failed ───────────────────────────────────────────────────────────

class _MobileFailedBody extends StatelessWidget {
  const _MobileFailedBody({Key? key, required this.color}) : super(key: key);

  final OColor color;

  @override
  Widget build(BuildContext context) {
    final message = Provider.of<DioNotifier>(context).uploadFilesFailure?.message
        ?? 'Something went wrong.';

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
            const Spacer(),
            Center(
              child: Image.asset(
                oImage.faliure,
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'Upload failed',
                style: GoogleFonts.inter(
                  color: color.secondary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: color.secondaryOnBackground,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => locator<AppRouter>().pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  oApp.currentConfig?.upload.errorButtonText ?? 'Try again',
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
