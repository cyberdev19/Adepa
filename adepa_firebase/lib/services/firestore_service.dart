import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../data/constants.dart';
import 'auth_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  // ─── Collections ──────────────────────────────────────────────
  CollectionReference get _posts => _db.collection('posts');
  CollectionReference _comments(String postId) =>
      _db.collection('posts').doc(postId).collection('comments');
  CollectionReference get _votes => _db.collection('votes');

  // ─── Posts ────────────────────────────────────────────────────

  /// Real-time stream of posts, optionally filtered by tag.
  Stream<List<Post>> postsStream({String? tag}) {
    Query query = _posts.orderBy('createdAt', descending: true).limit(50);
    if (tag != null && tag != 'all') {
      query = query.where('tag', isEqualTo: tag);
    }
    return query.snapshots().map(
      (snap) => snap.docs.map((d) => Post.fromDoc(d)).toList(),
    );
  }

  /// Create a new post.
  Future<void> createPost({
    required String text,
    required String tag,
  }) async {
    final colors = AdepaColors.postColorHex;
    final colorHex = colors[DateTime.now().millisecond % colors.length];
    await _posts.add({
      'text': text,
      'tag': tag,
      'colorHex': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
      'votes': 1,
      'commentCount': 0,
      'reactions': {},
      'authorId': _auth.uid,
    });
  }

  // ─── Votes ────────────────────────────────────────────────────

  /// Returns the user's current vote for a post: -1, 0, or 1.
  Future<int> getUserVote(String postId) async {
    final uid = _auth.uid;
    if (uid == null) return 0;
    final doc = await _votes.doc('${uid}_$postId').get();
    if (!doc.exists) return 0;
    return (doc.data() as Map<String, dynamic>)['vote'] ?? 0;
  }

  /// Cast or remove a vote on a post.
  Future<void> votePost(String postId, int newDir) async {
    final uid = _auth.uid;
    if (uid == null) return;

    final voteRef = _votes.doc('${uid}_$postId');
    final postRef = _posts.doc(postId);
    final voteDoc = await voteRef.get();
    final prevVote = voteDoc.exists
        ? (voteDoc.data() as Map<String, dynamic>)['vote'] ?? 0
        : 0;

    final delta = newDir == prevVote ? -prevVote : newDir - prevVote;
    final finalVote = newDir == prevVote ? 0 : newDir;

    await _db.runTransaction((tx) async {
      tx.set(voteRef, {'vote': finalVote, 'postId': postId, 'uid': uid});
      tx.update(postRef, {'votes': FieldValue.increment(delta)});
    });
  }

  // ─── Comments ─────────────────────────────────────────────────

  /// Real-time stream of comments for a post.
  Stream<List<Comment>> commentsStream(String postId) {
    return _comments(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Comment.fromMap(
                  d.data() as Map<String, dynamic>, d.id)).toList());
  }

  /// Add a comment to a post.
  Future<void> addComment(String postId, String text) async {
    final colors = AdepaColors.postColorHex;
    final colorHex = colors[DateTime.now().millisecond % colors.length];
    final batch = _db.batch();

    final commentRef = _comments(postId).doc();
    batch.set(commentRef, {
      'text': text,
      'colorHex': colorHex,
      'createdAt': FieldValue.serverTimestamp(),
      'authorId': _auth.uid,
    });

    batch.update(_posts.doc(postId), {
      'commentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // ─── Reactions ────────────────────────────────────────────────

  /// Toggle an emoji reaction on a post.
  Future<void> toggleReaction(
      String postId, String emoji, bool currentlyReacted) async {
    await _posts.doc(postId).update({
      'reactions.$emoji':
          currentlyReacted ? FieldValue.increment(-1) : FieldValue.increment(1),
    });
  }
}
