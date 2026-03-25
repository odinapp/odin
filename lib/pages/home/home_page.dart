import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/utilities/responsive.dart';

part 'widgets/main_container.dart';
part 'widgets/bg_illustration.dart';
part 'widgets/primary_button.dart';
part 'widgets/header_title.dart';
part 'widgets/divider.dart';
part 'widgets/secondary_button.dart';

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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          MainContainer(color: color),
          54.toVerticalSizedBox,
          const OrDivider(),
          SecondaryButton(color: color),
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
    final files = await locator<FileService>().pickMultipleFiles();
    if (files != null) {
      locator<AppRouter>().push(UploadRoute(uploadFiles: files));
    }
  }

  void _onReceive() {
    locator<AppRouter>().push(const DownloadRoute());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            // Wordmark
            Text(
              oApp.currentConfig?.home.title ?? 'odin',
              style: GoogleFonts.inter(
                color: color.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            // Headline
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
            const Spacer(),
            // Background illustration — smaller on mobile, bottom-right texture
            Align(
              alignment: Alignment.centerRight,
              child: Image.asset(
                oImage.odinBG,
                width: 180,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 16),
            // Send files button (primary)
            _MobilePrimaryButton(
              color: color,
              onPressed: () => _onSend(context),
            ),
            const SizedBox(height: 12),
            // Receive files button (secondary)
            _MobileSecondaryButton(color: color, onPressed: _onReceive),
            const SizedBox(height: 24),
          ],
        ),
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
        onPressed: onPressed,
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
        onPressed: onPressed,
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
                color: color.secondaryOnBackground,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            SvgPicture.asset(
              oImage.cloudDownload,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                color.secondaryOnBackground,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
