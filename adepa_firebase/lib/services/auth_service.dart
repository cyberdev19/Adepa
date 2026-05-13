import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  String? get uid => _auth.currentUser?.uid;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in anonymously. Called once on app start.
  Future<User?> signInAnonymously() async {
    try {
      if (_auth.currentUser != null) return _auth.currentUser;
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Auth error: $e');
      return null;
    }
  }
}
