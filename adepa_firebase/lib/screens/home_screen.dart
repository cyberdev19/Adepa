import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/constants.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _fs = FirestoreService();
  String _filter = 'all';
  String _selectedTag = 'accra';
  int _navIndex = 0;
  final _postCtrl = TextEditingController();
  bool _posting = false;

  Future<void> _submitPost() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) { _snack('Write something first!'); return; }
    setState(() => _posting = true);
    await _fs.createPost(text: text, tag: _selectedTag);
    _postCtrl.clear();
    setState(() { _posting = false; _filter = 'all'; });
    _snack('Posted! 🇬🇭');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.outfit(fontSize: 14)),
      backgroundColor: AdepaColors.ghGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdepaColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _Header(),
            _Tabs(filter: _filter, onFilter: (f) => setState(() => _filter = f)),
            Expanded(
              child: StreamBuilder<List<Post>>(
                stream: _fs.postsStream(tag: _filter == 'all' ? null : _filter),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AdepaColors.ghGold),
                    );
                  }
                  if (snap.hasError) {
                    return Center(
                      child: Text('Something went wrong 😕',
                          style: GoogleFonts.outfit(color: AdepaColors.textSecondary)),
                    );
                  }
                  final posts = snap.data ?? [];
                  if (posts.isEmpty) return _EmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    itemCount: posts.length,
                    itemBuilder: (ctx, i) => PostCard(
                      post: posts[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailScreen(post: posts[i]),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _Composer(
              controller: _postCtrl,
              selectedTag: _selectedTag,
              posting: _posting,
              onTagSelected: (t) => setState(() => _selectedTag = t),
              onPost: _submitPost,
            ),
            _BottomNav(
              index: _navIndex,
              onTap: (i) {
                setState(() => _navIndex = i);
                if (i != 0) {
                  final msgs = ['', 'Explore cities coming soon! 🇬🇭',
                      'Search coming soon!', 'Your profile is anonymous 😎'];
                  _snack(msgs[i]);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: AdepaColors.bg,
        border: Border(bottom: BorderSide(color: AdepaColors.border)),
      ),
      child: Row(
        children: [
          ClipOval(
            child: SizedBox(
              width: 34, height: 34,
              child: Column(children: [
                Expanded(child: Container(color: AdepaColors.ghRed)),
                Expanded(child: Container(color: AdepaColors.ghGold)),
                Expanded(child: Container(color: AdepaColors.ghGreen)),
              ]),
            ),
          ),
          const SizedBox(width: 10),
          RichText(
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 22, fontWeight: FontWeight.w700,
                  color: AdepaColors.textPrimary, letterSpacing: -0.5),
              children: const [
                TextSpan(text: 'Ade'),
                TextSpan(text: 'pa',
                    style: TextStyle(color: AdepaColors.ghGold)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AdepaColors.ghGold.withOpacity(0.12),
              border: Border.all(color: AdepaColors.ghGold.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Icon(Icons.location_on_rounded,
                  size: 14, color: AdepaColors.ghGold),
              const SizedBox(width: 4),
              Text('Accra',
                  style: GoogleFonts.outfit(
                      fontSize: 12, color: AdepaColors.ghGold,
                      fontWeight: FontWeight.w500)),
            ]),
          ),
          const SizedBox(width: 10),
          Stack(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AdepaColors.bg3, shape: BoxShape.circle,
                border: Border.all(color: AdepaColors.border)),
              child: const Icon(Icons.notifications_outlined,
                  size: 18, color: AdepaColors.textSecondary),
            ),
            Positioned(
              top: 6, right: 6,
              child: Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: AdepaColors.ghRed, shape: BoxShape.circle,
                  border: Border.all(color: AdepaColors.bg, width: 1.5)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  final String filter;
  final Function(String) onFilter;

  const _Tabs({required this.filter, required this.onFilter});

  @override
  Widget build(BuildContext context) {
    final allTabs = [
      {'key': 'all', 'label': '🔥 Trending'},
      ...AdepaTags.tags.entries.map((e) => {'key': e.key, 'label': e.value}),
    ];
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: AdepaColors.bg,
        border: Border(bottom: BorderSide(color: AdepaColors.border))),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: allTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (ctx, i) {
          final tab = allTabs[i];
          final active = filter == tab['key'];
          return GestureDetector(
            onTap: () => onFilter(tab['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: active ? AdepaColors.ghGold : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: active ? AdepaColors.ghGold : AdepaColors.border)),
              child: Center(
                child: Text(tab['label']!,
                    style: GoogleFonts.outfit(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: active ? Colors.black : AdepaColors.textSecondary)),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String selectedTag;
  final bool posting;
  final Function(String) onTagSelected;
  final VoidCallback onPost;

  const _Composer({
    required this.controller, required this.selectedTag,
    required this.posting, required this.onTagSelected, required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: AdepaColors.bg,
        border: Border(top: BorderSide(color: AdepaColors.border))),
      child: Column(children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: AdepaTags.tags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (ctx, i) {
              final entry = AdepaTags.tags.entries.toList()[i];
              final selected = selectedTag == entry.key;
              return GestureDetector(
                onTap: () => onTagSelected(entry.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: selected
                        ? AdepaColors.ghGold.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: selected
                            ? AdepaColors.ghGold.withOpacity(0.4)
                            : AdepaColors.border)),
                  child: Center(
                    child: Text(entry.value,
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: selected
                                ? AdepaColors.ghGold
                                : AdepaColors.textSecondary)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: null,
                style: GoogleFonts.outfit(
                    fontSize: 14, color: AdepaColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Whaddup Ghana? Say something...',
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
              onTap: posting ? null : onPost,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: posting
                        ? AdepaColors.ghGold.withOpacity(0.5)
                        : AdepaColors.ghGold,
                    borderRadius: BorderRadius.circular(12)),
                child: posting
                    ? const Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black),
                        ))
                    : const Icon(Icons.send_rounded,
                        color: Colors.black, size: 20),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int index;
  final Function(int) onTap;
  const _BottomNav({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.explore_rounded, 'label': 'Explore'},
      {'icon': Icons.search_rounded, 'label': 'Search'},
      {'icon': Icons.person_rounded, 'label': 'Me'},
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AdepaColors.bg2,
        border: Border(top: BorderSide(color: AdepaColors.border))),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = index == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(items[i]['icon'] as IconData,
                      size: 24,
                      color: active
                          ? AdepaColors.ghGold
                          : AdepaColors.textSecondary),
                  const SizedBox(height: 4),
                  Text(items[i]['label'] as String,
                      style: GoogleFonts.outfit(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: active
                              ? AdepaColors.ghGold
                              : AdepaColors.textSecondary)),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🇬🇭', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text('No posts here yet.\nBe the first!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                  fontSize: 15, color: AdepaColors.textSecondary, height: 1.5)),
        ],
      ),
    );
  }
}
