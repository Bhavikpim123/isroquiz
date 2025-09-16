import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart' as app_models;
import '../models/firebase_user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/mock_firebase_service.dart';
import '../services/local_profile_service.dart';

// Auth state enum
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  awaitingVerification,
}

// Auth state class
class AuthState {
  final AuthStatus status;
  final app_models.User? user; // Legacy user model for compatibility
  final AppUser? appUser; // Firebase user model
  final String? error;
  final String? pendingEmail; // For OTP verification

  AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.appUser,
    this.error,
    this.pendingEmail,
  });

  AuthState copyWith({
    AuthStatus? status,
    app_models.User? user,
    AppUser? appUser,
    String? error,
    String? pendingEmail,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      appUser: appUser ?? this.appUser,
      error: error ?? this.error,
      pendingEmail: pendingEmail ?? this.pendingEmail,
    );
  }
}

// Auth notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuthService _authService;
  final FirestoreService _firestoreService;
  final MockFirebaseService _mockService;
  final LocalProfileService _localProfileService;
  bool _useFirebase = true;

  AuthNotifier(
    this._authService,
    this._firestoreService,
    this._mockService,
    this._localProfileService,
  ) : super(AuthState()) {
    // Try to listen to Firebase auth state changes, fall back to mock if fails
    try {
      _authService.authStateChanges.listen((firebaseUser) {
        if (firebaseUser != null) {
          _handleUserSignedIn(firebaseUser);
        } else {
          _handleUserSignedOut();
        }
      });
    } catch (e) {
      print('Firebase unavailable, using mock service: $e');
      _useFirebase = false;
    }
  }

  // Send OTP for authentication
  Future<void> sendOTP(String email) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (_useFirebase) {
        try {
          await _authService.sendOTP(email);
          state = state.copyWith(
            status: AuthStatus.awaitingVerification,
            pendingEmail: email,
            error: null,
          );
          return;
        } catch (e) {
          print('Firebase OTP failed, using mock: $e');
          _useFirebase = false;
        }
      }

      // Use mock service as fallback
      state = state.copyWith(
        status: AuthStatus.awaitingVerification,
        pendingEmail: email,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> verifyOTP(String email, String otp) async {
    // Validate OTP format
    if (otp.length != 6) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Invalid OTP. Please enter a 6-digit code.',
      );
      return;
    }

    state = state.copyWith(status: AuthStatus.loading);

    try {
      // Try Firebase first, fall back to mock if it fails
      if (_useFirebase) {
        try {
          final userCredential = await _authService.verifyOTPAndSignIn(
            email,
            otp,
          );
          if (userCredential != null) {
            // Firebase authentication successful
            // The auth state listener will handle the rest
            return;
          }
        } catch (e) {
          print('Firebase verification failed, using mock: $e');
          _useFirebase = false;
        }
      }

      // Use mock service as fallback
      final success = await _mockService.signInWithEmail(email);
      if (success && _mockService.currentUser != null) {
        final mockUser = _mockService.currentUser!;

        final user = app_models.User(
          id: mockUser.id,
          email: mockUser.email,
          name: mockUser.displayName ?? email.split('@')[0],
          joinDate: mockUser.createdAt,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          appUser: mockUser,
          error: null,
          pendingEmail: null,
        );
      } else {
        throw Exception('Authentication failed');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Authentication failed: ${e.toString()}',
      );
    }
  }

  // Handle user signed in
  Future<void> _handleUserSignedIn(firebase_auth.User firebaseUser) async {
    try {
      // Get or create user in Firestore
      AppUser? appUser = await _firestoreService.getUser(firebaseUser.uid);

      if (appUser == null) {
        // Create new user
        appUser = AppUser(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName,
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _firestoreService.createUser(appUser);
      } else {
        // Update last login
        await _firestoreService.updateLastLogin(firebaseUser.uid);
        appUser = appUser.copyWith(lastLoginAt: DateTime.now());
      }

      // Create legacy user for compatibility
      final user = app_models.User(
        id: appUser.id,
        email: appUser.email,
        name: appUser.displayName ?? appUser.email.split('@')[0],
        joinDate: appUser.createdAt,
      );

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        appUser: appUser,
        error: null,
        pendingEmail: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Failed to load user data: $e',
      );
    }
  }

  // Handle user signed out
  void _handleUserSignedOut() {
    // Clear local profile data
    _localProfileService.clearLocalData();

    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      user: null,
      appUser: null,
      error: null,
      pendingEmail: null,
    );
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.signOut();
      // The auth state listener will handle the state update
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Check auth status on app start
  Future<void> checkAuthStatus() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      await _handleUserSignedIn(firebaseUser);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    final currentAppUser = state.appUser;
    if (currentAppUser == null) return;

    try {
      // Update Firebase Auth profile
      await _authService.updateProfile(
        displayName: displayName,
        photoURL: photoUrl,
      );

      // Update Firestore
      final updatedAppUser = currentAppUser.copyWith(
        displayName: displayName,
        photoUrl: photoUrl,
      );

      await _firestoreService.updateUser(updatedAppUser);

      // Update local state
      final updatedUser = state.user?.copyWith(name: displayName);

      state = state.copyWith(user: updatedUser, appUser: updatedAppUser);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update profile: $e');
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    final currentAppUser = state.appUser;
    if (currentAppUser == null) return;

    try {
      // Delete user data from Firestore
      await _firestoreService.deleteUserData(currentAppUser.id);

      // Delete Firebase Auth account
      await _authService.deleteAccount();

      // State will be updated by auth state listener
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete account: $e');
    }
  }

  // Sign in with email and password
  Future<void> signInWithEmailPassword(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (_useFirebase) {
        try {
          final userCredential = await _authService.signInWithEmailPassword(
            email,
            password,
          );
          // Firebase authentication successful
          // The auth state listener will handle the rest
          return;
        } catch (e) {
          print('Firebase sign in failed, using mock: $e');
          _useFirebase = false;
        }
      }

      // Use mock service as fallback for sign in
      final success = await _mockService.signInWithEmailPassword(
        email,
        password,
      );
      if (success && _mockService.currentUser != null) {
        final mockUser = _mockService.currentUser!;

        final user = app_models.User(
          id: mockUser.id,
          email: mockUser.email,
          name: mockUser.displayName ?? email.split('@')[0],
          joinDate: mockUser.createdAt,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          appUser: mockUser,
          error: null,
        );
      } else {
        throw Exception('Invalid email or password');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Sign in failed: ${e.toString()}',
      );
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmailPassword(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      if (_useFirebase) {
        try {
          final userCredential = await _authService
              .createAccountWithEmailPassword(email, password);
          // Firebase authentication successful
          // The auth state listener will handle the rest
          return;
        } catch (e) {
          print('Firebase sign up failed, using mock: $e');
          _useFirebase = false;
        }
      }

      // Use mock service as fallback for sign up
      final success = await _mockService.createAccountWithEmailPassword(
        email,
        password,
      );
      if (success && _mockService.currentUser != null) {
        final mockUser = _mockService.currentUser!;

        final user = app_models.User(
          id: mockUser.id,
          email: mockUser.email,
          name: mockUser.displayName ?? email.split('@')[0],
          joinDate: mockUser.createdAt,
        );

        state = state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          appUser: mockUser,
          error: null,
        );
      } else {
        throw Exception('Account creation failed');
      }
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: 'Sign up failed: ${e.toString()}',
      );
    }
  }
}

// Service providers
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final mockFirebaseServiceProvider = Provider<MockFirebaseService>((ref) {
  return MockFirebaseService();
});

// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  final firestoreService = ref.watch(firestoreServiceProvider);
  final mockService = ref.watch(mockFirebaseServiceProvider);
  final localProfileService = LocalProfileService();
  return AuthNotifier(
    authService,
    firestoreService,
    mockService,
    localProfileService,
  );
});

// Current user provider (legacy)
final currentUserProvider = Provider<app_models.User?>((ref) {
  return ref.watch(authProvider).user;
});

// Current app user provider
final currentAppUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).appUser;
});

// Is authenticated provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).status == AuthStatus.authenticated;
});
