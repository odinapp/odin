import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/model/pending_upload.dart';
import 'package:odin/providers/pending_uploads_notifier.dart';
import 'package:provider/provider.dart';

/// Reduces awkward line breaks in the middle of file extensions (e.g. `.jp` / `g`).
String pendingUploadFileLabel(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot >= name.length - 1) return name;
  return '${name.substring(0, dot)}.\u2060${name.substring(dot + 1)}';
}

/// Lists uploads stored locally that can still be deleted on the server.
class PendingUploadsHomeSection extends StatefulWidget {
  const PendingUploadsHomeSection({
    super.key,
    required this.color,
    this.compact = true,
    this.maxListHeight = 200,
    this.showHeader = true,
  });

  final OColor color;
  final bool compact;
  final double maxListHeight;

  /// When false (e.g. bottom sheet), only the list or empty state is shown;
  /// the parent supplies the title row.
  final bool showHeader;

  @override
  State<PendingUploadsHomeSection> createState() =>
      _PendingUploadsHomeSectionState();
}

class _PendingUploadsHomeSectionState extends State<PendingUploadsHomeSection> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PendingUploadsNotifier>().refresh();
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PendingUpload upload,
  ) async {
    final color = widget.color;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: color.cardOnBackground,
        title: Text(
          'Delete upload?',
          style: GoogleFonts.inter(
            color: color.secondary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This permanently removes the files from Odin. This cannot be undone.',
          style: GoogleFonts.inter(
            color: color.secondaryOnBackground,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(
                color: color.error,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final notifier = context.read<PendingUploadsNotifier>();
    final success = await notifier.deleteUploadOnServer(upload);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Upload removed from Odin.'
              : 'Could not delete. Check your connection and try again.',
          style: GoogleFonts.inter(
            color: color.secondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color.cardOnBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final titleSize = widget.compact ? 13.0 : 15.0;
    final bodySize = widget.compact ? 12.0 : 13.0;
    final tokenSize = widget.compact ? 11.0 : 12.0;

    return Consumer<PendingUploadsNotifier>(
      builder: (context, pending, _) {
        if (pending.items.isEmpty) {
          if (!widget.showHeader) {
            return _PendingUploadsSheetEmpty(color: color);
          }
          return const SizedBox.shrink();
        }

        final list = SizedBox(
          height: widget.maxListHeight,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const ClampingScrollPhysics(),
            itemCount: pending.items.length,
            separatorBuilder: (context, index) =>
                SizedBox(height: widget.compact ? 8 : 10),
            itemBuilder: (context, index) {
              final u = pending.items[index];
              final rawTitle = u.fileSummary ?? u.shareToken;
              final title = pendingUploadFileLabel(rawTitle);
              return Container(
                padding: EdgeInsets.symmetric(
                  horizontal: widget.compact ? 12 : 14,
                  vertical: widget.compact ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: color.cardOnBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.secondaryOnBackground.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: color.secondary,
                              fontSize: bodySize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: widget.compact ? 4 : 6),
                          Text(
                            'Token: ${u.shareToken}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: color.secondaryOnBackground,
                              fontSize: tokenSize,
                            ),
                          ),
                          Text(
                            PendingUploadsNotifier.timeRemainingLabel(u),
                            style: GoogleFonts.inter(
                              color: color.primary,
                              fontSize: tokenSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: widget.compact ? 6 : 8),
                    IconButton(
                      tooltip: 'Copy token',
                      style: IconButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.all(10),
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: u.shareToken));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Token copied',
                              style: GoogleFonts.inter(
                                color: color.secondary,
                                fontSize: 14,
                              ),
                            ),
                            backgroundColor: color.cardOnBackground,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.copy_rounded,
                        size: widget.compact ? 18 : 20,
                        color: color.secondaryOnBackground,
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      onPressed: () => _confirmDelete(context, u),
                      child: Text(
                        'Delete',
                        style: GoogleFonts.inter(
                          color: color.error,
                          fontSize: bodySize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );

        if (!widget.showHeader) {
          return list;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your uploads',
              style: GoogleFonts.inter(
                color: color.secondary,
                fontSize: titleSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: widget.compact ? 6 : 8),
            Text(
              'Remove files from Odin before they expire. Copy the token to share again.',
              style: GoogleFonts.inter(
                color: color.secondaryOnBackground,
                fontSize: tokenSize,
                height: 1.35,
              ),
            ),
            SizedBox(height: widget.compact ? 10 : 12),
            list,
          ],
        );
      },
    );
  }
}

class _PendingUploadsSheetEmpty extends StatelessWidget {
  const _PendingUploadsSheetEmpty({required this.color});

  final OColor color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: color.secondaryOnBackground.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            'No active uploads',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'After you send files, they show up here so you can copy the token or delete early.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: color.secondaryOnBackground,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
