import 'dart:async';

import 'package:cache_money_attendance/auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  String? user = '';
  String userState = '';
  int counter = 0;
  int latestTimeIn = 0;
  int latestTimeOut = 0;
  int totalTimeMilliseconds = 0;
  String totalTime = '';
  String sessionTime = '';
  int totalSessions = 0;

  Timer? timer;

  final textController = TextEditingController();

  DatabaseReference ref = FirebaseDatabase.instance.ref();
  var auth = Auth().firebaseAuth;

  // The build method is called every time the widget is updated, so be careful with what logic goes here. Generally, UI elements should go here and logic should go in initState or in button presses.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Visibility(
            visible: auth.currentUser != null,
            // If the user is not signed in (the above condition is false - i.e. the user is null), show the replacement widget (the sign-in button and note about pop-ups)
            replacement: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Note: Sign-in works via pop-up, which is not supported '
                      'on all browsers. If you are having trouble signing in, '
                      'try enabling pop-ups or using a different browser.'),
                ),
                SignInButton(context: context),
              ],
            ),
            // If the user is signed in, show the user data and the sign-out and time buttons
            child: Column(children: <Widget>[
              Text('Email: ${auth.currentUser?.email}'),
              Text('Name: ${auth.currentUser?.displayName}'),
              Text('Total time: $totalTime'),
              Text('Session time: $sessionTime'),
              Text('Total sessions: $totalSessions'),
              Text('Current state: $userState'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: toggleButton(context),
              ),
              Padding(padding: const EdgeInsets.all(8.0), child: SignOutButton(context: context)),
            ]),
          ),
        ],
      ),
    );
  }

  // initState is called when the widget is first created so it's where logic than should run at load time should go
  @override
  void initState() {
    super.initState();

    // Listen for changes in the user's authentication state (i.e. they sign in or out)
    auth.authStateChanges().listen((User? newUser) {
      if (newUser != null) {
        configUser();
        reload();
      }
    });

    /// This timer is used to update the time every second. There is a warning because we never actually refer back to the timer but you can safely ignore it.
    /// Essentially what it does is calculate the time the user has been checked in and the total time, once per second, to display on the home page.
    /// Note that the calculations here are NOT actually used to write to the database on check-out. That's in the cloud function!
    Timer timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (userState == 'in') {
          int liveSessionTimeMilliseconds = DateTime.now().millisecondsSinceEpoch - latestTimeIn;
          int liveTotalTimeMilliseconds = liveSessionTimeMilliseconds + totalTimeMilliseconds;
          Duration liveSessionTimeDuration = Duration(milliseconds: liveSessionTimeMilliseconds);
          Duration liveTotalTimeDuration = Duration(milliseconds: liveTotalTimeMilliseconds);
          totalTime =
              '${liveTotalTimeDuration.inHours}:${liveTotalTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${liveTotalTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
          sessionTime =
              '${liveSessionTimeDuration.inHours}:${liveSessionTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${liveSessionTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
        } else {
          totalTime =
              '${Duration(milliseconds: totalTimeMilliseconds).inHours}:${Duration(milliseconds: totalTimeMilliseconds).inMinutes.remainder(60).toString().padLeft(2, '0')}:${Duration(milliseconds: totalTimeMilliseconds).inSeconds.remainder(60).toString().padLeft(2, '0')}';
          sessionTime = '0:00:00';
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  /// Gets the current user (potentially null), and if the user is not null, fetches the user's data from the database
  void configUser() {
    user = auth.currentUser?.uid;
    if (user != null && user != '') {
      fetchData();
    }
  }

  /// This function is called when a user signs in for the first time (i.e. does not exist in the database). It sets the user's data to the default values.
  void newUser() {
    setUserVal('/totalTime', 0);
    setUserVal('/state', 'out');
    setUserVal('/counter', 0);
    setUserVal('/admin', false);
    setUserVal('/totalSessions', 0);
    setUserVal('/name', auth.currentUser?.displayName as Object);
    setUserVal('/email', auth.currentUser?.email as Object);
  }

  /// Fetches the user's data from the database and sets the local (widget state) variables to the fetched database values.
  void fetchData() async {
    DataSnapshot snapshot = await ref.child(user!).get();

    if (snapshot.value == null) {
      newUser();
    } else {
      setState(() {
        totalTimeMilliseconds = snapshot.child('totalTime').value as int;
        totalSessions = snapshot.child('totalSessions').value as int;
        Duration totalTimeDuration = Duration(milliseconds: totalTimeMilliseconds);
        // This is just formatting the time to be in the format HH:MM:SS
        totalTime =
            '${totalTimeDuration.inHours}:${totalTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${totalTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
        userState = snapshot.child('state').value.toString();
        counter = snapshot.child('counter').value as int;
        if (userState == 'in') {
          latestTimeIn = snapshot.child('sessions').child(counter.toString()).child('timeIn').value as int;
        }
      });
    }
  }

  /// Refreshes the user's data from the database. This is called when a change is detected in the user's state (i.e. they start or stop the time).
  void reload() {
    ref.child('$user/state').onValue.listen((event) async {
      fetchData();
    });
  }

  /// This just exists to avoid duplicate users, since most people will have a school and personal Google account.
  /// TODO: Maybe just limit it to Lab accounts (with hardcoded exceptions for mentors?) 
  showNewUserAlertDialog(BuildContext context) {
    AlertDialog confirmNewUserDialog() {
      return AlertDialog(
        title: const Text('Confirm New User?'),
        content: Text('The user $user does not exist in the database; are you sure you want to create a new user?'),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                newUser();
              },
              child: const Text('Confirm')),
        ],
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return confirmNewUserDialog();
      },
    );
  }

  /// Helper function to set a value in the database as a child of the current user.
  void setUserVal(String key, Object val) {
    ref.child('$user$key').set(val).then((result) => {fetchData()}).catchError((e) => {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e)),
          )
        });
  }

  /// This is the button that toggles the user's state (i.e. starts or stops the time).
  ElevatedButton toggleButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        if (userState == '') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in first'),
              duration: Duration(seconds: 1),
            ),
          );
        } else {
          if (userState == 'in') {
            checkOut();
          } else {
            checkIn();
          }
        }
      },
      child: Text(userState == 'in' ? 'Stop time' : 'Start time'),
    );
  }

  /// There's very little we actually need to do here; just store the current time and set the state. All calculations are handled on check out.
  void checkIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checked in'),
        duration: Duration(milliseconds: 500),
      ),
    );
    latestTimeIn = DateTime.now().millisecondsSinceEpoch;
    setUserVal('/sessions/$counter/timeIn', latestTimeIn);
    setUserVal('/state', 'in');
  }

  void checkOut() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checked out'),
        duration: Duration(milliseconds: 500),
      ),
    );

    // We use a cloud function here so that it can be called automatically if the user forgets to check out.
    await FirebaseFunctions.instance.httpsCallable('manualSignOut').call().then((value) => fetchData());
  }
}
