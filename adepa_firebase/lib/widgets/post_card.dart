import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post.dart';
import '../data/constants.dart';
import '../services/firestore_service.dart';
import 'report_sheet.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback onTap;

  const PostCard({super.key, required this.post, required this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _fs = FirestoreService();
  int _userVote = 0;

  @override
  void initState() {
    super.initState();
    _fs.getUserVote(widget.post.id).then((v) {
      if (mounted) setState(() => _userVote = v);
    });
  }

  Future<void> _vote(int dir) async {
    await _fs.votePost(widget.post.id, dir);
    final v = await _fs.getUserVote(widget.post.id);
    if (mounted) setState(() => _userVote = v);
  }

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdepaColors.bg2,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: AdepaColors.border,
                borderRadius: BorderRadius.circular(4)),
          ),
          ListTile(
            leading: const Icon(Icons.flag_rounded,
                color: AdepaColors.ghRed, size: 20),
            title: Text('Report post',
                style: GoogleFonts.outfit(
                    fontSize: 15, color: AdepaColors.ghRed)),
            onTap: () {
              Navigator.pop(context);
              showReportSheet(context, postId: widget.post.id);
            },
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_rounded,
                color: AdepaColors.textSecondary, size: 20),
            title: Text('Not interested',
                style: GoogleFonts.outfit(
                    fontSize: 15, color: AdepaColors.textSecondary)),
            onTap: () => Navigator.pop(context),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    if (post.hidden) return const SizedBox.shrink();

    final tagLabel = AdepaTags.tags[post.tag] ?? post.tag;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AdepaColors.bg2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdepaColors.border),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: post.accentColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: post.accentColor.withOpacity(0.15),
                        child: const Text('👤', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Text('Anonymous',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AdepaColors.textSecondary,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(timeago.format(post.createdAt),
                          style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AdepaColors.textSecondary)),
                      GestureDetector(
                        onTap: () => _showPostMenu(context),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(Icons.more_horiz,
                              size: 18, color: AdepaColors.textSecondary),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(tagLabel,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AdepaColors.ghGold,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Text(post.text,
                        style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: AdepaColors.textPrimary,
                            height: 1.55)),
                    const SizedBox(height: 12),
                    const Divider(color: AdepaColors.border, height: 1),
                    const SizedBox(height: 10),
                    Row(children: [
                      _ActionBtn(
                        icon: Icons.arrow_upward_rounded,
                        label: post.votes.toString(),
                        isActive: _userVote == 1,
                        activeColor: AdepaColors.ghGold,
                        onTap: () => _vote(1),
                      ),
                      const SizedBox(width: 12),
                      _ActionBtn(
                        icon: Icons.arrow_downward_rounded,
                        isActive: _userVote == -1,
                        activeColor: AdepaColors.ghRed,
                        onTap: () => _vote(-1),
                      ),
                      const Spacer(),
                      _ActionBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: post.commentCount.toString(),
                        onTap: widget.onTap,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon, this.label,
    this.isActive = false,
    this.activeColor = AdepaColors.textSecondary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : AdepaColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          if (label != null) ...[
            const SizedBox(width: 4),
            Text(label!,
                style: GoogleFonts.outfit(
                    fontSize: 13, color: color, fontWeight: FontWeight.w600)),
          ],
        ]),
      ),
    );
  }
}
