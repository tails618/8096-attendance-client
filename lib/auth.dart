import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:html' as html;

class Auth {
  Auth();

  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  Future<UserCredential> signInWithGoogle() async {
    // Create a new provider
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope("https://www.googleapis.com/auth/userinfo.email");
    googleProvider.addScope("https://www.googleapis.com/auth/userinfo.profile");
    // googleProvider
    //     .setCustomParameters({'login_hint': 'user@ucls.uchicago.edu'});

    // Once signed in, return the UserCredential
    return await firebaseAuth.signInWithPopup(googleProvider);

    // Or use signInWithRedirect
    // return await FirebaseAuth.instance.signInWithRedirect(googleProvider);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  bool isSignedIn() {
    return firebaseAuth.currentUser != null;
  }
}

class SignInButton extends StatelessWidget {
  const SignInButton({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Auth().signInWithGoogle();
        // FirebaseAuth.instance.authStateChanges().listen((User? user) {});
      },
      child: const Text('Sign in to account'),
    );
  }

  // void isAdmin() {
  //   if (Auth().firebaseAuth.currentUser != null) {
  //     DatabaseReference ref = FirebaseDatabase.instance.ref();
  //     ref.child(Auth().firebaseAuth.currentUser!.uid).once().then((DataSnapshot snapshot) {
  //       if (snapshot.value?['admin'] == true) {
  //         return true;
  //       } else {
  //         return false;
  //       }
  //     });
  //   } else {
  //     return false;
  //   }
  // }
}

class SignOutButton extends StatelessWidget {
  const SignOutButton({
    super.key,
    required this.context,
  });

  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // onPressed: () {
      //   Auth().signOut();
      //   html.window.location.reload();
      // },
      onPressed: () => showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Note'),
          content: const Text('This will sign you out of your Google account. It will NOT stop the clock. If you want to stop the clock, press the "stop time" button.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Auth().signOut();
                html.window.location.reload();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
      child: const Text('Sign out of account'),
    );
  }
}
