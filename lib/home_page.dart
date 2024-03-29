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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Visibility(
            visible: auth.currentUser != null,
            replacement: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text(
                      'Note: Sign-in works via pop-up, which is not supported '
                      'on all browsers. If you are having trouble signing in, '
                      'try enabling pop-ups or using a different browser.'),
                ),
                SignInButton(context: context),
              ],
            ),
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
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SignOutButton(context: context)),
            ]),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    auth.authStateChanges().listen((User? newUser) {
      if (newUser != null) {
        configUser();
        reload();
      }
    });
    Timer timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        if (userState == 'in') {
          int liveSessionTimeMilliseconds =
              DateTime.now().millisecondsSinceEpoch - latestTimeIn;
          int liveTotalTimeMilliseconds =
              liveSessionTimeMilliseconds + totalTimeMilliseconds;
          Duration liveSessionTimeDuration =
              Duration(milliseconds: liveSessionTimeMilliseconds);
          Duration liveTotalTimeDuration =
              Duration(milliseconds: liveTotalTimeMilliseconds);
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

  void configUser() {
    user = auth.currentUser?.uid;
    if (user != null && user != '') {
      fetchData();
    }
  }

  void newUser() {
    setUserVal('/totalTime', 0);
    setUserVal('/state', 'out');
    setUserVal('/counter', 0);
    setUserVal('/admin', false);
    setUserVal('/totalSessions', 0);
    setUserVal('/name', auth.currentUser?.displayName as Object);
    setUserVal('/email', auth.currentUser?.email as Object);
  }

  void fetchData() async {
    DataSnapshot snapshot = await ref.child(user!).get();
    if (snapshot.value == null) {
      newUser();
    } else {
      setState(() {
        totalTimeMilliseconds = snapshot.child('totalTime').value as int;
        totalSessions = snapshot.child('totalSessions').value as int;
        Duration totalTimeDuration =
            Duration(milliseconds: totalTimeMilliseconds);
        totalTime =
            '${totalTimeDuration.inHours}:${totalTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${totalTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
        userState = snapshot.child('state').value.toString();
        counter = snapshot.child('counter').value as int;
        print(counter);
        if (userState == 'in') {
          latestTimeIn = snapshot
              .child('sessions')
              .child(counter.toString())
              .child('timeIn')
              .value as int;
        }
      });
    }
  }

  void reload() {
    ref.child('$user/state').onValue.listen((event) async {
      // Fetch the entire user data when a change is detected in user/state
      DataSnapshot snapshot = await ref.child(user!).get();
      if (snapshot.value == null) {
        newUser();
      } else {
        setState(() {
          totalTimeMilliseconds = snapshot.child('totalTime').value as int;
          totalSessions = snapshot.child('totalSessions').value as int;
          Duration totalTimeDuration =
              Duration(milliseconds: totalTimeMilliseconds);
          totalTime =
              '${totalTimeDuration.inHours}:${totalTimeDuration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${totalTimeDuration.inSeconds.remainder(60).toString().padLeft(2, '0')}';
          userState = snapshot.child('state').value.toString();
          counter = snapshot.child('counter').value as int;
          if (userState == 'in') {
            latestTimeIn = snapshot
                .child('sessions')
                .child(counter.toString())
                .child('timeIn')
                .value as int;
          }
        });
      }
    });
  }

  showNewUserAlertDialog(BuildContext context) {
    AlertDialog confirmNewUserDialog() {
      return AlertDialog(
        title: const Text('Confirm New User?'),
        content: Text(
            'The user $user does not exist in the database; are you sure you want to create a new user?'),
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

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return confirmNewUserDialog();
      },
    );
  }

  void setUserVal(String child, Object val) {
    ref
        .child('$user$child')
        .set(val)
        .then((result) => {fetchData()})
        .catchError((e) => {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e)),
              )
            });
  }

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
            // checkOut();
            await FirebaseFunctions.instance.httpsCallable('manualSignOut').call().then((value) => fetchData());
            // print(FirebaseFunctions.instance.httpsCallable('manualSignOut').call({}).toString());
          } else {
            checkIn();
          }
        }
      },
      child: Text(userState == 'in' ? 'Stop time' : 'Start time'),
    );
  }

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

  void checkOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checked out'),
        duration: Duration(milliseconds: 500),
      ),
    );

    latestTimeOut = DateTime.now().millisecondsSinceEpoch;

    setUserVal('/sessions/$counter/timeOut', latestTimeOut);

    int duration = latestTimeOut - latestTimeIn;
    int newTotalTime = totalTimeMilliseconds + duration;

    int newSessions = 0;

    if (duration >= const Duration(hours: 6, minutes: 30).inMilliseconds) {
      newSessions = 2;
    } else if (duration >=
        const Duration(hours: 2, minutes: 30).inMilliseconds) {
      newSessions = 1;
    }

    setUserVal('/sessions/$counter/sessions', newSessions);

    setUserVal('/totalSessions', totalSessions + newSessions);

    setUserVal('/totalTime', newTotalTime);
    setUserVal('/state', 'out');
    setUserVal('/counter', counter + 1);
  }
}
