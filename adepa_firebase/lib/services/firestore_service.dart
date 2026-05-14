import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../data/constants.dart';
import 'auth_service.dart';
import 'moderation_service.dart';

class PostException implements Exception {
  final String message;
  PostException(this.message);
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();
  final ModerationService _mod = ModerationService();

  CollectionReference get _posts => _db.collection('posts');
  CollectionReference _comments(String postId) =>
      _db.collection('posts').doc(postId).collection('comments');
  CollectionReference get _votes => _db.collection('votes');

  // ─── Posts ────────────────────────────────────────────────────

  Stream<List<Post>> postsStream({String? tag}) {
    Query query = _posts
        .where('hidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(50);
    if (tag != null && tag != 'all') {
      query = query.where('tag', isEqualTo: tag);
    }
    return query.snapshots().map(
      (snap) => snap.docs.map((d) => Post.fromDoc(d)).toList(),
    );
  }

  /// Create a post. Throws [PostException] if content is banned or rate limited.
  Future<void> createPost({required String text, required String tag}) async {
    final uid = _auth.uid;
    if (uid == null) throw PostException('Not authenticated');

    // 1. Check if user is banned
    final banned = await _mod.isCurrentUserBanned();
    if (banned) throw PostException('Your account has been suspended.');

    // 2. Check banned words
    if (_mod.containsBannedWords(text)) {
      throw PostException(
          'Your post contains content that violates community guidelines.');
    }

    // 3. Rate limit: max 1 post per 60 seconds
    final recent = await _posts
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (recent.docs.isNotEmpty) {
      final lastPost = (recent.docs.first.data()
          as Map<String, dynamic>)['createdAt'] as Timestamp?;
      if (lastPost != null) {
        final diff = DateTime.now().difference(lastPost.toDate());
        if (diff.inSeconds < 60) {
          final wait = 60 - diff.inSeconds;
          throw PostException('Slow down! Wait ${wait}s before posting again.');
        }
      }
    }

    // 4. Clean the text (soft filter)
    final cleanText = _mod.filterText(text);

    // 5. Write to Firestore
    final colors = AdepaColors.postColorHex;
    final colorHex = colors[DateTime.now().millisecond % colors.length];
    await _posts.add({
      'text': cleanText,
      'tag': tag,
      'colorHex': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
      'votes': 1,
      'commentCount': 0,
      'reportCount': 0,
      'hidden': false,
      'reactions': {},
      'authorId': uid,
    });
  }

  // ─── Votes ────────────────────────────────────────────────────

  Future<int> getUserVote(String postId) async {
    final uid = _auth.uid;
    if (uid == null) return 0;
    final doc = await _votes.doc('${uid}_$postId').get();
    if (!doc.exists) return 0;
    return (doc.data() as Map<String, dynamic>)['vote'] ?? 0;
  }

  Future<void> votePost(String postId, int newDir) async {
    final uid = _auth.uid;
    if (uid == null) return;

    final voteRef = _votes.doc('${uid}_$postId');
    final postRef = _posts.doc(postId);
    final voteDoc = await voteRef.get();
    final prevVote =
        voteDoc.exists ? (voteDoc.data() as Map<String, dynamic>)['vote'] ?? 0 : 0;

    final delta = newDir == prevVote ? -prevVote : newDir - prevVote;
    final finalVote = newDir == prevVote ? 0 : newDir;

    await _db.runTransaction((tx) async {
      tx.set(voteRef, {'vote': finalVote, 'postId': postId, 'uid': uid});
      tx.update(postRef, {'votes': FieldValue.increment(delta)});
    });
  }

  // ─── Comments ─────────────────────────────────────────────────

  Stream<List<Comment>> commentsStream(String postId) {
    return _comments(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Comment.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addComment(String postId, String text) async {
    final uid = _auth.uid;
    if (uid == null) return;

    final banned = await _mod.isCurrentUserBanned();
    if (banned) throw PostException('Your account has been suspended.');

    if (_mod.containsBannedWords(text)) {
      throw PostException('Comment violates community guidelines.');
    }

    final cleanText = _mod.filterText(text);
    final colors = AdepaColors.postColorHex;
    final colorHex = colors[DateTime.now().millisecond % colors.length];
    final batch = _db.batch();

    final commentRef = _comments(postId).doc();
    batch.set(commentRef, {
      'text': cleanText,
      'colorHex': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
      'authorId': uid,
    });
    batch.update(_posts.doc(postId), {
      'commentCount': FieldValue.increment(1),
    });
    await batch.commit();
  }

  // ─── Reactions ────────────────────────────────────────────────

  Future<void> toggleReaction(
      String postId, String emoji, bool currentlyReacted) async {
    await _posts.doc(postId).update({
      'reactions.$emoji': currentlyReacted
          ? FieldValue.increment(-1)
          : FieldValue.increment(1),
    });
  }
}
