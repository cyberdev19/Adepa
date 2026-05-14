import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/constants.dart';
import '../services/moderation_service.dart';

/// Shows a bottom sheet letting the user report a post or comment.
Future<void> showReportSheet(
  BuildContext context, {
  required String postId,
  String? commentId,
}) async {
  await showModalBottomSheet(
    context: context,
    backgroundColor: AdepaColors.bg2,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ReportSheet(postId: postId, commentId: commentId),
  );
}

class _ReportSheet extends StatefulWidget {
  final String postId;
  final String? commentId;

  const _ReportSheet({required this.postId, this.commentId});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _mod = ModerationService();
  ReportReason? _selected;
  bool _submitting = false;
  bool _done = false;

  Future<void> _submit() async {
    if (_selected == null) return;
    setState(() => _submitting = true);

    bool success;
    if (widget.commentId != null) {
      success = await _mod.reportComment(
          widget.postId, widget.commentId!, _selected!);
    } else {
      success = await _mod.reportPost(widget.postId, _selected!);
    }

    if (mounted) {
      setState(() { _submitting = false; _done = true; });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            success ? 'Report submitted. Thank you 🙏' : 'Already reported.',
            style: GoogleFonts.outfit(fontSize: 14),
          ),
          backgroundColor: success ? AdepaColors.ghGreen : AdepaColors.bg3,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('✅', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('Report submitted',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdepaColors.textPrimary)),
        ]),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AdepaColors.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Report this post',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AdepaColors.textPrimary)),
          const SizedBox(height: 6),
          Text('Why are you reporting this?',
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AdepaColors.textSecondary)),
          const SizedBox(height: 16),
          // Reason chips
          ...ReportReason.values.map((r) => _ReasonTile(
                reason: r,
                selected: _selected == r,
                onTap: () => setState(() => _selected = r),
              )),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selected == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdepaColors.ghRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AdepaColors.bg3,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text('Submit Report',
                      style: GoogleFonts.outfit(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportReason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile(
      {required this.reason, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AdepaColors.ghRed.withOpacity(0.1)
              : AdepaColors.bg3,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AdepaColors.ghRed.withOpacity(0.5)
                : AdepaColors.border,
          ),
        ),
        child: Row(
          children: [
            Text(reason.label,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: selected
                        ? AdepaColors.ghRed
                        : AdepaColors.textPrimary,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AdepaColors.ghRed, size: 18),
          ],
        ),
      ),
    );
  }
}
