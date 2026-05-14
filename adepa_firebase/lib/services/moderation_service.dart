import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

/// Reasons a user can report a post or comment.
enum ReportReason {
  spam('Spam'),
  hate('Hate speech'),
  harassment('Harassment'),
  misinformation('Misinformation'),
  explicit('Explicit content'),
  other('Other');

  const ReportReason(this.label);
  final String label;
}

class ModerationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _auth = AuthService();

  CollectionReference get _reports => _db.collection('reports');
  CollectionReference get _banned => _db.collection('banned_users');

  // ─── Banned words (Ghana-aware) ───────────────────────────────
  // Extend this list as the community grows.
  static const List<String> _bannedWords = [
    // English profanity
    'fuck', 'shit', 'bitch', 'asshole', 'cunt', 'nigger', 'faggot',
    // Twi / Ghanaian slurs (transliterated)
    'twea', 'kyinkyinga', 'damirifa',
    // Harassment triggers
    'kill yourself', 'kys', 'go die',
  ];

  /// Returns true if text contains any banned word.
  bool containsBannedWords(String text) {
    final lower = text.toLowerCase();
    return _bannedWords.any((word) => lower.contains(word));
  }

  /// Cleans text by replacing banned words with asterisks.
  String filterText(String text) {
    String result = text;
    for (final word in _bannedWords) {
      final regex = RegExp(word, caseSensitive: false);
      result = result.replaceAll(regex, '*' * word.length);
    }
    return result;
  }

  // ─── Reporting ────────────────────────────────────────────────

  /// Report a post. Returns false if already reported by this user.
  Future<bool> reportPost(
      String postId, ReportReason reason, {String? note}) async {
    final uid = _auth.uid;
    if (uid == null) return false;

    final reportId = '${uid}_$postId';
    final existing = await _reports.doc(reportId).get();
    if (existing.exists) return false; // Already reported

    final batch = _db.batch();

    // Save report
    batch.set(_reports.doc(reportId), {
      'postId': postId,
      'reporterId': uid,
      'reason': reason.name,
      'note': note ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'post',
      'resolved': false,
    });

    // Increment report count on post
    batch.update(_db.collection('posts').doc(postId), {
      'reportCount': FieldValue.increment(1),
    });

    await batch.commit();

    // Auto-hide if report threshold reached
    await _checkAndHidePost(postId);
    return true;
  }

  /// Report a comment.
  Future<bool> reportComment(
      String postId, String commentId, ReportReason reason) async {
    final uid = _auth.uid;
    if (uid == null) return false;

    final reportId = '${uid}_${commentId}';
    final existing = await _reports.doc(reportId).get();
    if (existing.exists) return false;

    await _reports.doc(reportId).set({
      'postId': postId,
      'commentId': commentId,
      'reporterId': uid,
      'reason': reason.name,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'comment',
      'resolved': false,
    });

    return true;
  }

  /// Auto-hide post if reportCount >= 3.
  Future<void> _checkAndHidePost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    if (!doc.exists) return;
    final data = doc.data() as Map<String, dynamic>;
    final count = data['reportCount'] ?? 0;
    if (count >= 3) {
      await _db.collection('posts').doc(postId).update({'hidden': true});
    }
  }

  // ─── Admin actions ────────────────────────────────────────────

  /// Admin: restore a hidden post.
  Future<void> restorePost(String postId) async {
    await _db.collection('posts').doc(postId).update({
      'hidden': false,
      'reportCount': 0,
    });
  }

  /// Admin: permanently delete a post.
  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

  /// Admin: ban a user by UID.
  Future<void> banUser(String uid, String reason) async {
    await _banned.doc(uid).set({
      'uid': uid,
      'reason': reason,
      'bannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Check if the current user is banned.
  Future<bool> isCurrentUserBanned() async {
    final uid = _auth.uid;
    if (uid == null) return false;
    final doc = await _banned.doc(uid).get();
    return doc.exists;
  }

  // ─── Admin streams ────────────────────────────────────────────

  /// Stream of hidden (auto-moderated) posts for admin review.
  Stream<QuerySnapshot> hiddenPostsStream() {
    return _db
        .collection('posts')
        .where('hidden', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Stream of all unresolved reports.
  Stream<QuerySnapshot> unresolvedReportsStream() {
    return _reports
        .where('resolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Mark a report as resolved.
  Future<void> resolveReport(String reportId) async {
    await _reports.doc(reportId).update({'resolved': true});
  }
}
