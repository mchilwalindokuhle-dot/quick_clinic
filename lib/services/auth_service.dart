import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // 1. Register with Email, Password, Role, and Clinic (for Admins)
  Future<String?> registerWithEmail({
    required String fullName,
    required String email,
    required String password,
    String role = 'patient',
    String? clinicId,
    String? clinicName,
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      User? user = result.user;
      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'role': role,
          'clinicId': clinicId,
          'clinicName': clinicName,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // 2. Login with Email
  Future<String?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // 3. Google Sign-In
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return 'Sign in cancelled.';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential result = await _auth.signInWithCredential(
        credential,
      );
      final user = result.user;

      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'fullName': user.displayName ?? 'Google User',
            'email': user.email ?? '',
            'role': 'patient',
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'An error occurred: ${e.toString()}';
    }
  }

  // 4. Password Reset
  Future<String?> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _getErrorMessage(e.code);
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // 5. Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  // 6. Error Handler
  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a minute.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
