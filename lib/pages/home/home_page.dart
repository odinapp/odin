import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/constants/sharing_policy.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/utilities/mobile_a11y.dart';
import 'package:odin/utilities/responsive.dart';
import 'package:odin/widgets/pending_uploads_home_section.dart';
import 'package:provider/provider.dart';
import 'package:odin/providers/pending_uploads_notifier.dart';

part 'widgets/main_container.dart';
part 'widgets/bg_illustration.dart';
part 'widgets/primary_button.dart';
part 'widgets/header_title.dart';
part 'widgets/divider.dart';
part 'widgets/secondary_button.dart';

void showOdinHomeSnackBar(BuildContext context, String message) {
  if (!context.mounted) return;
  final color = OColor.withContext(context);
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final snackBg = isDark ? color.cardOnBackground : color.lBackgroundContainer;
  final snackFg = isDark ? color.secondary : color.lSecondary;
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      backgroundColor: snackBg,
      content: Text(
        message,
        style: color.textStyle(
          color: snackFg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
      ),
    ),
  );
}

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

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
            ? _MobileBody(color: color)
            : const _Body(),
      ),
    );
  }
}

// ── Desktop layout (unchanged) ──────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);

    return desktopClampedTextScale(
      context,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            MainContainer(color: color),
            54.toVerticalSizedBox,
            const OrDivider(),
            SecondaryButton(color: color),
            16.toVerticalSizedBox,
            _DesktopPolicyStrip(color: color),
            32.toVerticalSizedBox,
            SizedBox(
              width: 1040.toAutoScaledWidth,
              child: PendingUploadsHomeSection(
                color: color,
                compact: false,
                maxListHeight: 220,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Policy line aligned with mobile home; visible copy + semantics for desktop.
class _DesktopPolicyStrip extends StatelessWidget {
  const _DesktopPolicyStrip({required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Files expire after ${SharingPolicy.fileLifetimeHours} hours. '
          'Maximum upload size ${SharingPolicy.maxUploadShortLabel}.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Text(
              '${SharingPolicy.fileLifetimeHours}h expiry · '
              '${SharingPolicy.maxUploadShortLabel} max',
              textAlign: TextAlign.center,
              style: color.textStyle(
                color: color.secondaryOnBackground,
                fontSize: 13.toAutoScaledFont,
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: 0.12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile layout ────────────────────────────────────────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody({Key? key, required this.color}) : super(key: key);

  final OColor color;

  Future<void> _onSend(BuildContext context) async {
    final pick = await locator<FileService>().pickMultipleFiles();
    if (!context.mounted) return;
    if (pick.errorMessage != null) {
      showOdinHomeSnackBar(context, pick.errorMessage!);
      return;
    }
    final files = pick.files;
    if (files != null) {
      locator<AppRouter>().push(UploadRoute(uploadFiles: files));
    }
  }

  void _onReceive() {
    locator<AppRouter>().push(const DownloadRoute());
  }

  @override
  Widget build(BuildContext context) {
    return mobileClampedTextScale(
      context,
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          // Brand texture behind copy — subdued, upper-right (.impeccable: not hero).
          Positioned(
            bottom: 40,
            right: 0,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.36,
                child: Image.asset(
                  oImage.odinBG,
                  width: MediaQuery.sizeOf(context).width * 0.85,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          oApp.currentConfig?.home.title ?? 'odin',
                          style: GoogleFonts.inter(
                            color: color.primary,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _MobilePendingUploadsAction(color: color),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Open-source\neasy file\nsharing for\neveryone.',
                    style: GoogleFonts.inter(
                      color: color.secondary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(flex: 2),
                  _MobilePrimaryButton(
                    color: color,
                    onPressed: () => _onSend(context),
                  ),
                  const SizedBox(height: 12),
                  _MobileSecondaryButton(color: color, onPressed: _onReceive),
                  const SizedBox(height: 10),
                  _MobilePolicyStrip(color: color),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showMobilePendingUploadsSheet(
  BuildContext context, {
  required OColor color,
}) async {
  if (!MediaQuery.disableAnimationsOf(context)) {
    HapticFeedback.lightImpact();
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: color.background,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    clipBehavior: Clip.antiAlias,
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final listMaxH = (mq.size.height * 0.55).clamp(240.0, 480.0);
      final bottomInset = mq.padding.bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 12, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: color.secondaryOnBackground.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your uploads',
                        style: GoogleFonts.inter(
                          color: color.secondary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Delete early or copy a share token.',
                        style: GoogleFonts.inter(
                          color: color.secondaryOnBackground,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  tooltip: 'Close',
                  style: IconButton.styleFrom(
                    foregroundColor: color.secondaryOnBackground,
                    minimumSize: const Size(48, 48),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PendingUploadsHomeSection(
              color: color,
              showHeader: false,
              maxListHeight: listMaxH,
            ),
          ],
        ),
      );
    },
  );
}

class _MobilePendingUploadsAction extends StatelessWidget {
  const _MobilePendingUploadsAction({required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Consumer<PendingUploadsNotifier>(
      builder: (context, pending, _) {
        final n = pending.items.length;
        final icon = Icon(
          Icons.upload_outlined,
          size: 24,
          color: n > 0 ? color.primary : color.secondaryOnBackground,
        );
        final button = mobileToolbarIconButton(
          context: context,
          tooltip: n == 0 ? 'Your uploads' : 'Your uploads, $n active',
          onPressed: () {
            showMobilePendingUploadsSheet(context, color: color);
          },
          icon: icon,
        );
        if (n == 0) return button;
        return button;
      },
    );
  }
}

/// Single muted line; full wording in [Semantics] for screen readers.
class _MobilePolicyStrip extends StatelessWidget {
  const _MobilePolicyStrip({required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          'Files expire after ${SharingPolicy.fileLifetimeHours} hours. '
          'Maximum upload size ${SharingPolicy.maxUploadShortLabel}.',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ExcludeSemantics(
            child: Text(
              '${SharingPolicy.fileLifetimeHours}h expiry · ${SharingPolicy.maxUploadShortLabel} max',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 1.25,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobilePrimaryButton extends StatelessWidget {
  const _MobilePrimaryButton({
    Key? key,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  final OColor color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              oApp.currentConfig?.home.primaryButtonText ?? 'Send files',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SvgPicture.asset(
              oImage.arrowRight,
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSecondaryButton extends StatelessWidget {
  const _MobileSecondaryButton({
    Key? key,
    required this.color,
    required this.onPressed,
  }) : super(key: key);

  final OColor color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color.cardOnBackground,
          foregroundColor: color.secondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              oApp.currentConfig?.home.secondaryButtonText ?? 'Receive files',
              style: GoogleFonts.inter(
                color: color.secondary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SvgPicture.asset(
              oImage.cloudDownload,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(color.secondary, BlendMode.srcIn),
            ),
          ],
        ),
      ),
    );
  }
}
