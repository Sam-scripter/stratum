import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register with Email and Password
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;

      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);
        await user.reload();

        // Send email verification
        await user.sendEmailVerification();

        // Save user profile in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'emailVerified': false, // Track verification status
        });
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Registration failed';
    }
  }

  // Login with Email and Password
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCred.user;
      
      if (user != null) {
        // Check if email is verified
        await user.reload();
        if (!user.emailVerified) {
          // Send verification email if not verified
          await user.sendEmailVerification();
          throw 'Please verify your email before signing in. A verification email has been sent.';
        }
      }
      
      return user;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Login failed';
    }
  }

  // Google Sign-in
  Future<User?> signInWithGoogle() async {
    try {
      // Create the GoogleSignIn instance
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled the sign-in
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential for Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;

      // Save user to Firestore if new user
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final docSnap = await docRef.get();
        if (!docSnap.exists) {
          await docRef.set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'createdAt': FieldValue.serverTimestamp(),
            'emailVerified': user.emailVerified,
          });
        }
      }

      return user;
    } catch (e) {
      print("Error during Google sign-in: $e");
      throw Exception('An error occurred during Google sign-in. Please try again.');
    }
  }

  // Forgot Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw e.message ?? 'Password reset failed';
    }
  }

  // Check email verification status
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    await user.reload();
    return user.emailVerified;
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user is currently signed in.';
    
    await user.sendEmailVerification();
  }

  // Resend email verification
  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user is currently signed in.';
    
    if (user.emailVerified) {
      throw 'Email is already verified.';
    }
    
    await user.sendEmailVerification();
  }

  // Logout
  Future<void> signOut() async {
    await _auth.signOut();
    final GoogleSignIn googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get userChanges => _auth.authStateChanges();

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}

