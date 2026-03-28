part of '../view.dart';

// ── Desktop: scaled card + token entry uses same 8-box control as mobile ─────

class _DesktopDownloadBody extends StatefulWidget {
  const _DesktopDownloadBody({required this.color});

  final OColor color;

  @override
  State<_DesktopDownloadBody> createState() => _DesktopDownloadBodyState();
}

class _DesktopDownloadBodyState extends State<_DesktopDownloadBody> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _token = '';
  final ODebounce _debounce = ODebounce(const Duration(milliseconds: 400));

  OColor get color => widget.color;

  /// Match mobile `_TokenBoxInput` defaults so the control looks identical.
  static const double _kBoxW = 36;
  static const double _kBoxH = 54;
  static const double _kGap = 10;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    final n = locator<OdinNotifier>();
    n.downloadFileSuccess = null;
    n.downloadFileFailure = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        locator<OdinNotifier>().apiStatus = ApiStatus.init;
        locator<OdinNotifier>().miniApiStatus = ApiStatus.init;
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchMetadata() async {
    await locator<OdinNotifier>().fetchFilesMetadata(_token, (c, t) {});
  }

  Future<void> _download() async {
    final filePath = await locator<OdinNotifier>().getSaveDirectory();
    await locator<OdinNotifier>().downloadFile(_token, filePath, (c, t) {
      logger.d('Downloaded $c/$t');
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = Provider.of<OdinNotifier>(context);
    final miniStatus = notifier.miniApiStatus;
    final apiStatus = notifier.apiStatus;

    if (notifier.downloadFileSuccess != null) {
      return _DesktopDownloadSuccessCard(color: color);
    }

    final tokenRowWidth = _TokenBoxInput.totalRowWidth(
      boxWidth: _kBoxW,
      gap: _kGap,
    );

    return desktopClampedTextScale(
      context,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.toAutoScaledWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
            child: Container(
              width: 1040.toAutoScaledWidth,
              height: 688.toAutoScaledHeight,
              decoration: BoxDecoration(
                color: color.cardOnBackground,
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
                border: Border.all(color: color.borderSubtleOnBackground),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 4.toAutoScaledHeight,
                    left: 19.toAutoScaledWidth,
                    child: _DesktopCardBackLink(color: color),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.only(top: 44.toAutoScaledHeight),
                      child: Column(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: 60.toAutoScaledWidth,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 28.toAutoScaledHeight),
                                  Text(
                                    oApp.currentConfig?.token.title ??
                                        'Receive files',
                                    style: color.textStyle(
                                      color: color.secondary,
                                      fontSize: 48.toAutoScaledFont,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  SizedBox(height: 16.toAutoScaledHeight),
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: 640.toAutoScaledWidth,
                                    ),
                                    child: Text(
                                      oApp.currentConfig?.token.description ??
                                          'Paste the token someone sent you. '
                                              'We verify it before '
                                              'you download.',
                                      style: color.textStyle(
                                        color: color.secondaryOnBackground,
                                        fontSize: 22.toAutoScaledFont,
                                        fontWeight: FontWeight.w400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 36.toAutoScaledHeight),
                                  SizedBox(
                                    width: double.infinity,
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final token = SizedBox(
                                          width: tokenRowWidth,
                                          child: _TokenBoxInput(
                                            color: color,
                                            controller: _controller,
                                            focusNode: _focusNode,
                                            miniStatus: miniStatus,
                                            boxWidth: _kBoxW,
                                            boxHeight: _kBoxH,
                                            boxGap: _kGap,
                                            glyphFontSize: 20,
                                            boxRadius: 10,
                                            onChanged: (value) {
                                              setState(() => _token = value);
                                              if (value.length >= 6) {
                                                _debounce.call(_fetchMetadata);
                                              } else {
                                                locator<OdinNotifier>()
                                                        .miniApiStatus =
                                                    ApiStatus.init;
                                              }
                                            },
                                          ),
                                        );
                                        final cta = _DesktopDownloadCta(
                                          color: color,
                                          enabled:
                                              miniStatus == ApiStatus.success,
                                          loading:
                                              apiStatus == ApiStatus.loading,
                                          onPressed: _download,
                                        );
                                        final gap = 32.toAutoScaledWidth;
                                        if (constraints.maxWidth <
                                            tokenRowWidth +
                                                gap +
                                                300.toAutoScaledWidth) {
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Center(child: token),
                                              SizedBox(
                                                height: 24.toAutoScaledHeight,
                                              ),
                                              Center(child: cta),
                                            ],
                                          );
                                        }
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            token,
                                            SizedBox(width: gap),
                                            cta,
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20.toAutoScaledHeight),
                                  _DesktopCardMetadataLine(
                                    color: color,
                                    miniStatus: miniStatus,
                                    errorMessage: notifier
                                        .fetchFilesMetadataFailure
                                        ?.message,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopCardBackLink extends StatelessWidget {
  const _DesktopCardBackLink({required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => locator<AppRouter>().pop(),
      style: ButtonStyle(
        overlayColor: MaterialStateProperty.all(Colors.transparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            oImage.arrowLeft,
            width: 16.toAutoScaledWidth,
            height: 16.toAutoScaledHeight,
            colorFilter: ColorFilter.mode(
              color.secondaryOnBackground,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 16.toAutoScaledWidth),
          Text(
            oApp.currentConfig?.token.backButtonText ?? 'Back',
            style: color.textStyle(
              color: color.secondaryOnBackground,
              fontSize: 24.toAutoScaledFont,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopDownloadCta extends StatelessWidget {
  const _DesktopDownloadCta({
    required this.color,
    required this.enabled,
    required this.loading,
    required this.onPressed,
  });

  final OColor color;
  final bool enabled;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final miniOk = enabled;
    return SizedBox(
      width: 300.toAutoScaledWidth,
      height: 96.toAutoScaledHeight,
      child: ElevatedButton(
        onPressed: miniOk && !loading ? onPressed : null,
        style:
            ElevatedButton.styleFrom(
              backgroundColor: color.primary,
              disabledBackgroundColor: color.secondaryContainerOnBackground,
              foregroundColor: Colors.white,
              disabledForegroundColor: color.secondaryOnBackground,
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
              ),
            ).copyWith(
              overlayColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.hovered) &&
                    miniOk &&
                    !loading) {
                  return Colors.white.withValues(alpha: 0.14);
                }
                if (states.contains(MaterialState.focused) && miniOk) {
                  return Colors.white.withValues(alpha: 0.18);
                }
                return null;
              }),
            ),
        child: loading
            ? SizedBox(
                width: 28.toAutoScaledWidth,
                height: 28.toAutoScaledHeight,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      oApp.currentConfig?.token.primaryButtonText ??
                          'Download files',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: color.textStyle(
                        color: miniOk
                            ? Colors.white
                            : color.secondaryOnBackground,
                        fontSize: 28.toAutoScaledFont,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.toAutoScaledWidth),
                  SvgPicture.asset(
                    oImage.cloudDownload,
                    width: 28.toAutoScaledWidth,
                    height: 28.toAutoScaledHeight,
                    colorFilter: ColorFilter.mode(
                      miniOk ? Colors.white : color.secondaryOnBackground,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DesktopCardMetadataLine extends StatelessWidget {
  const _DesktopCardMetadataLine({
    required this.color,
    required this.miniStatus,
    this.errorMessage,
  });

  final OColor color;
  final ApiStatus? miniStatus;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (miniStatus == ApiStatus.success) {
      final metadata = Provider.of<OdinNotifier>(
        context,
      ).fetchFilesMetadataSuccess?.filesMetadata;
      if (metadata == null) return SizedBox(height: 24.toAutoScaledHeight);

      final fileCount =
          metadata.fileCount ?? metadata.displayFiles?.length ?? 0;
      final totalSize = formatDownloadTotalFileSize(
        metadata.displayTotalFileSize,
      );
      final fileLabel = fileCount == 1 ? '1 file' : '$fileCount files';
      final names = (metadata.displayFiles ?? const [])
          .map((file) => file.path ?? '')
          .where((path) => path.isNotEmpty)
          .take(5)
          .toList(growable: false);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_rounded, color: color.primary, size: 20),
              SizedBox(width: 10.toAutoScaledWidth),
              Expanded(
                child: Text(
                  '$fileLabel · $totalSize — ready to download',
                  style: color.textStyle(
                    color: color.primary,
                    fontSize: 18.toAutoScaledFont,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          if (names.isNotEmpty) ...[
            SizedBox(height: 8.toAutoScaledHeight),
            ...names.map(
              (name) => Padding(
                padding: EdgeInsets.only(left: 30.toAutoScaledWidth),
                child: Text(
                  '• $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: color.textStyle(
                    color: color.secondaryOnBackground,
                    fontSize: 14.toAutoScaledFont,
                    fontWeight: FontWeight.w400,
                    height: 1.35,
                  ),
                ),
              ),
            ),
            if (fileCount > names.length)
              Padding(
                padding: EdgeInsets.only(left: 30.toAutoScaledWidth),
                child: Text(
                  '+${fileCount - names.length} more',
                  style: color.textStyle(
                    color: color.secondaryOnBackground,
                    fontSize: 14.toAutoScaledFont,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
          ],
        ],
      );
    }
    if (miniStatus == ApiStatus.failed) {
      return Text(
        friendlyDownloadMetadataError(errorMessage),
        style: color.textStyle(
          color: color.error,
          fontSize: 18.toAutoScaledFont,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      );
    }
    return SizedBox(height: 24.toAutoScaledHeight);
  }
}

class _DesktopDownloadSuccessCard extends StatefulWidget {
  const _DesktopDownloadSuccessCard({required this.color});

  final OColor color;

  @override
  State<_DesktopDownloadSuccessCard> createState() =>
      _DesktopDownloadSuccessCardState();
}

class _DesktopDownloadSuccessCardState
    extends State<_DesktopDownloadSuccessCard> {
  OColor get color => widget.color;

  String _subtitle(core.DownloadFileSuccess success) {
    if (success.extracted) {
      final count = success.extractedFiles.length;
      final dirName = success.directory!.path.split(RegExp(r'[/\\]')).last;
      return count == 1
          ? 'Extracted 1 file to $dirName'
          : 'Extracted $count files to $dirName';
    }
    if (success.file != null) {
      return 'Saved as ${success.file!.path.split(RegExp(r'[/\\]')).last}';
    }
    return 'Your files are saved on this device.';
  }

  Future<void> _openFile(core.DownloadFileSuccess success) async {
    final path = success.extracted
        ? success.directory!.path
        : success.file!.path;
    await OpenFilex.open(path);
  }

  Future<void> _showInFolder(core.DownloadFileSuccess success) async {
    final path = success.extracted
        ? success.directory!.path
        : success.file!.path;
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final success = Provider.of<OdinNotifier>(context).downloadFileSuccess;

    return desktopClampedTextScale(
      context,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.toAutoScaledWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
            child: Container(
              width: 1040.toAutoScaledWidth,
              height: 688.toAutoScaledHeight,
              decoration: BoxDecoration(
                color: color.cardOnBackground,
                borderRadius: BorderRadius.circular(20.toAutoScaledWidth),
                border: Border.all(color: color.borderSubtleOnBackground),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 4.toAutoScaledHeight,
                    left: 19.toAutoScaledWidth,
                    child: TextButton(
                      onPressed: () => locator<AppRouter>().popUntilRoot(),
                      style: ButtonStyle(
                        overlayColor: MaterialStateProperty.all(
                          Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            oImage.arrowLeft,
                            width: 16.toAutoScaledWidth,
                            height: 16.toAutoScaledHeight,
                            colorFilter: ColorFilter.mode(
                              color.secondaryOnBackground,
                              BlendMode.srcIn,
                            ),
                          ),
                          SizedBox(width: 16.toAutoScaledWidth),
                          Text(
                            oApp.currentConfig?.token.backButtonText ?? 'Back',
                            style: color.textStyle(
                              color: color.secondaryOnBackground,
                              fontSize: 24.toAutoScaledFont,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      60.toAutoScaledWidth,
                      56.toAutoScaledHeight,
                      60.toAutoScaledWidth,
                      40.toAutoScaledHeight,
                    ),
                    child: Column(
                      children: [
                        const Spacer(),
                        const _SuccessMarkWithDelight(desktopScale: true),
                        SizedBox(height: 28.toAutoScaledHeight),
                        Text(
                          'Download complete',
                          textAlign: TextAlign.center,
                          style: color.textStyle(
                            color: color.secondary,
                            fontSize: 36.toAutoScaledFont,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.35,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 12.toAutoScaledHeight),
                        Text(
                          success != null
                              ? _subtitle(success)
                              : 'Your files are saved on this device.',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: color.textStyle(
                            color: color.secondaryOnBackground,
                            fontSize: 20.toAutoScaledFont,
                            fontWeight: FontWeight.w400,
                            height: 1.45,
                          ),
                        ),
                        if (success != null) ...[
                          SizedBox(height: 6.toAutoScaledHeight),
                          Text(
                            success.outputPath,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: color.textStyle(
                              color: color.secondaryOnBackground.withValues(
                                alpha: 0.6,
                              ),
                              fontSize: 13.toAutoScaledFont,
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (success != null) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 96.toAutoScaledHeight,
                            child: ElevatedButton(
                              onPressed: () => _openFile(success),
                              style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor: color.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        20.toAutoScaledWidth,
                                      ),
                                    ),
                                  ).copyWith(
                                    overlayColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            MaterialState.hovered,
                                          )) {
                                            return Colors.white.withValues(
                                              alpha: 0.14,
                                            );
                                          }
                                          return null;
                                        }),
                                  ),
                              child: Text(
                                success.extracted ? 'Open folder' : 'Open file',
                                style: color.textStyle(
                                  color: Colors.white,
                                  fontSize: 28.toAutoScaledFont,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 12.toAutoScaledHeight),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 76.toAutoScaledHeight,
                                  child: OutlinedButton(
                                    onPressed: () => _showInFolder(success),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: color.borderSubtleOnBackground,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          20.toAutoScaledWidth,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Show in folder',
                                      style: color.textStyle(
                                        color: color.secondaryOnBackground,
                                        fontSize: 20.toAutoScaledFont,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.toAutoScaledWidth),
                              Expanded(
                                child: SizedBox(
                                  height: 76.toAutoScaledHeight,
                                  child: TextButton(
                                    onPressed: () =>
                                        locator<AppRouter>().popUntilRoot(),
                                    style: TextButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          20.toAutoScaledWidth,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'Back to home',
                                      style: color.textStyle(
                                        color: color.secondaryOnBackground,
                                        fontSize: 20.toAutoScaledFont,
                                        fontWeight: FontWeight.w600,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          SizedBox(
                            width: double.infinity,
                            height: 96.toAutoScaledHeight,
                            child: ElevatedButton(
                              onPressed: () =>
                                  locator<AppRouter>().popUntilRoot(),
                              style:
                                  ElevatedButton.styleFrom(
                                    backgroundColor: color.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        20.toAutoScaledWidth,
                                      ),
                                    ),
                                  ).copyWith(
                                    overlayColor:
                                        MaterialStateProperty.resolveWith((
                                          states,
                                        ) {
                                          if (states.contains(
                                            MaterialState.hovered,
                                          )) {
                                            return Colors.white.withValues(
                                              alpha: 0.14,
                                            );
                                          }
                                          return null;
                                        }),
                                  ),
                              child: Text(
                                'Back to home',
                                style: color.textStyle(
                                  color: Colors.white,
                                  fontSize: 28.toAutoScaledFont,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle entrance; [desktopScale] uses auto-scaled dimensions for the card.
class _SuccessMarkWithDelight extends StatelessWidget {
  const _SuccessMarkWithDelight({this.desktopScale = false});

  final bool desktopScale;

  @override
  Widget build(BuildContext context) {
    final double side = desktopScale ? 220.toAutoScaledWidth : 120;
    final child = Image.asset(
      oImage.success,
      width: side,
      height: desktopScale ? 220.toAutoScaledHeight : side,
      excludeFromSemantics: true,
    );

    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        return Opacity(
          opacity: t,
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        );
      },
    );
  }
}
