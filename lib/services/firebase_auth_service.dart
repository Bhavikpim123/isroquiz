import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Generate and store OTP (for demo purposes)
  final Map<String, String> _otpStorage = {};

  // Send OTP via email (simulated)
  Future<bool> sendOTP(String email) async {
    try {
      // Generate a 6-digit OTP
      final otp = _generateOTP();
      _otpStorage[email] = otp;

      // In a real app, you would send this OTP via email service
      // For demo, we'll just log it (you can remove this in production)
      print('OTP for $email: $otp');

      return true;
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP and sign in user
  Future<UserCredential?> verifyOTPAndSignIn(String email, String otp) async {
    try {
      // Check if OTP matches
      if (_otpStorage[email] != otp) {
        throw Exception('Invalid OTP');
      }

      // Remove used OTP
      _otpStorage.remove(email);

      // Try to sign in with existing user or create new one
      try {
        // Try to sign in with a temporary password
        final tempPassword = _generateTempPassword(email);
        return await _auth.signInWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
      } catch (e) {
        // If user doesn't exist, create new account
        final tempPassword = _generateTempPassword(email);
        return await _auth.createUserWithEmailAndPassword(
          email: email,
          password: tempPassword,
        );
      }
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Alternative: Direct email/password sign in for testing
  Future<UserCredential> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Create account with email/password for testing
  Future<UserCredential> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to create account: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    try {
      await currentUser?.delete();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  // Check if email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  // Reload user to get updated verification status
  Future<void> reloadUser() async {
    await currentUser?.reload();
  }

  // Generate OTP
  String _generateOTP() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  // Generate consistent temporary password for email
  String _generateTempPassword(String email) {
    // Generate a consistent password based on email for demo purposes
    // In production, use proper password generation and storage
    return 'TempPass123!' + email.hashCode.abs().toString();
  }

  // Get user display name
  String? get userDisplayName => currentUser?.displayName;

  // Get user email
  String? get userEmail => currentUser?.email;

  // Get user ID
  String? get userId => currentUser?.uid;

  // Update user profile
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      await currentUser?.updateDisplayName(displayName);
      if (photoURL != null) {
        await currentUser?.updatePhotoURL(photoURL);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    try {
      await currentUser?.sendEmailVerification();
    } catch (e) {
      throw Exception('Failed to send email verification: $e');
    }
  }
}
