// Ensure you've imported the necessary packages at the top
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      // Attempt to get the Google Sign-In account
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser != null) {
        // Get the authentication object from Google Sign In
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Use the credential to sign in with Firebase
        final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

        // Return the Firebase user
        return userCredential.user;
      } else {
        // User cancelled the Google Sign-In (returning null)
        print('Google sign-in was cancelled by the user.');
        return null;
      }
    } catch (e) {
      // Handle errors from the sign in process
      print('Error signing in with Google: $e');
      return null;
    }
  }
}

