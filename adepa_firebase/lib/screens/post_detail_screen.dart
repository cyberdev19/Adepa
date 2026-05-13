import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/post.dart';
import '../data/constants.dart';
import '../services/firestore_service.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _fs = FirestoreService();
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int _userVote = 0;
  Set<String> _myReactions = {};
  bool _submitting = false;

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

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    await _fs.addComment(widget.post.id, text);
    _commentCtrl.clear();
    setState(() => _submitting = false);
    await Future.delayed(const Duration(milliseconds: 200));
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _toggleReaction(String emoji) async {
    final reacted = _myReactions.contains(emoji);
    setState(() {
      reacted ? _myReactions.remove(emoji) : _myReactions.add(emoji);
    });
    await _fs.toggleReaction(widget.post.id, emoji, reacted);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final tagLabel = AdepaTags.tags[post.tag] ?? post.tag;

    return Scaffold(
      backgroundColor: AdepaColors.bg,
      appBar: AppBar(
        backgroundColor: AdepaColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AdepaColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Post',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AdepaColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AdepaColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Comment>>(
              stream: _fs.commentsStream(post.id),
              builder: (ctx, snap) {
                final comments = snap.data ?? [];
                return ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post card
                    _PostDetailCard(
                      post: post,
                      tagLabel: tagLabel,
                      userVote: _userVote,
                      myReactions: _myReactions,
                      onVote: _vote,
                      onReact: _toggleReaction,
                    ),
                    const SizedBox(height: 16),
                    // Comments header
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16, color: AdepaColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          '${comments.length} comment${comments.length != 1 ? 's' : ''}',
                          style: GoogleFonts.outfit(
                              fontSize: 13,
                              color: AdepaColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                        if (snap.connectionState == ConnectionState.waiting)
                          const Padding(
                            padding: EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 12, height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: AdepaColors.ghGold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Comments
                    ...comments.map((c) => _CommentCard(comment: c)),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: const BoxDecoration(
              color: AdepaColors.bg,
              border: Border(top: BorderSide(color: AdepaColors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentCtrl,
                    maxLines: null,
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: AdepaColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add a comment... 🇬🇭',
                      hintStyle: GoogleFonts.outfit(
                          fontSize: 14, color: AdepaColors.textSecondary),
                      filled: true,
                      fillColor: AdepaColors.bg3,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdepaColors.border)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AdepaColors.border)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: AdepaColors.ghGold.withOpacity(0.5))),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _submitting ? null : _submitComment,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: _submitting
                          ? AdepaColors.ghGold.withOpacity(0.5)
                          : AdepaColors.ghGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _submitting
                        ? const Center(
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black),
                            ),
                          )
                        : const Icon(Icons.send_rounded,
                            color: Colors.black, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _PostDetailCard extends StatelessWidget {
  final Post post;
  final String tagLabel;
  final int userVote;
  final Set<String> myReactions;
  final Function(int) onVote;
  final Function(String) onReact;

  const _PostDetailCard({
    required this.post,
    required this.tagLabel,
    required this.userVote,
    required this.myReactions,
    required this.onVote,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdepaColors.bg2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdepaColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                                fontSize: 12, color: AdepaColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(tagLabel,
                        style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AdepaColors.ghGold,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(post.text,
                        style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: AdepaColors.textPrimary,
                            height: 1.6)),
                    const SizedBox(height: 14),
                    // Emoji reactions
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: AdepaTags.emojis.map((emoji) {
                        final count = post.reactions[emoji] ?? 0;
                        final reacted = myReactions.contains(emoji);
                        return GestureDetector(
                          onTap: () => onReact(emoji),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: reacted
                                  ? AdepaColors.ghGold.withOpacity(0.15)
                                  : AdepaColors.bg3,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: reacted
                                    ? AdepaColors.ghGold.withOpacity(0.5)
                                    : AdepaColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(count.toString(),
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: reacted
                                              ? AdepaColors.ghGold
                                              : AdepaColors.textSecondary,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: AdepaColors.border, height: 1),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => onVote(1),
                          child: Row(children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 18,
                                color: userVote == 1
                                    ? AdepaColors.ghGold
                                    : AdepaColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(post.votes.toString(),
                                style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: userVote == 1
                                        ? AdepaColors.ghGold
                                        : AdepaColors.textSecondary)),
                          ]),
                        ),
                        const SizedBox(width: 14),
                        GestureDetector(
                          onTap: () => onVote(-1),
                          child: Icon(Icons.arrow_downward_rounded,
                              size: 18,
                              color: userVote == -1
                                  ? AdepaColors.ghRed
                                  : AdepaColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  final Comment comment;
  const _CommentCard({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdepaColors.bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdepaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: comment.color.withOpacity(0.15),
                child: const Text('👤', style: TextStyle(fontSize: 10)),
              ),
              const SizedBox(width: 7),
              Text('Anonymous',
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AdepaColors.textSecondary,
                      fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(timeago.format(comment.createdAt),
                  style: GoogleFonts.outfit(
                      fontSize: 11, color: AdepaColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(comment.text,
              style: GoogleFonts.outfit(
                  fontSize: 14, color: AdepaColors.textPrimary, height: 1.5)),
        ],
      ),
    );
  }
}
