import 'package:cache_money_attendance/auth.dart';
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
  int totalSessions = 0;

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
                  child: Text('Note: Sign-in works via pop-up, which is not supported '
                      'on all browsers. If you are having trouble signing in, '
                      'try enabling pop-ups or using a different browser.'),
                ),
               SignInButton(context: context),
              ],
            ),
            child: Column(children: <Widget>[
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SignOutButton(context: context)),
              Text('Email: ${auth.currentUser?.email}'),
              Text('Name: ${auth.currentUser?.displayName}'),
              Text('Total time: $totalTime'),
              Text('Total sessions: $totalSessions'),
              Text('Current state: $userState'),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: toggleButton(context),
              ),
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
      }
    });
  }

  void configUser() {
    user = auth.currentUser?.uid;
    if (user != null && user != '') {
      reload();
    }
  }

  void newUser() {
    setUserVal('/totalTime', 0);
    setUserVal('/state', 'out');
    setUserVal('/counter', 0);
    setUserVal('/admin', false);
    setUserVal('/totalSessions', 0);
  }

  void reload() async {
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
        .then((result) => {reload()})
        .catchError((e) => {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(e)),
              )
            });
  }

  ElevatedButton toggleButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
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
      child: Text(userState == 'in' ? 'Check out' : 'Check in'),
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
    setUserVal('/state', 'in');
    setUserVal('/sessions/$counter/timeIn', latestTimeIn);
  }

  void checkOut() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Checked out'),
        duration: Duration(milliseconds: 500),
      ),
    );

    latestTimeOut = DateTime.now().millisecondsSinceEpoch;

    setUserVal('/state', 'out');
    setUserVal('/sessions/$counter/timeOut', latestTimeOut);

    int duration = latestTimeOut - latestTimeIn;
    int newTotalTime = totalTimeMilliseconds + duration;

    int newSessions = 0;

    if (duration >= const Duration(hours: 6, minutes: 30).inMilliseconds){
      newSessions = 2;
    } else if (duration >= const Duration(hours: 2, minutes: 30).inMilliseconds){
      newSessions = 1;
    }

    setUserVal('/sessions/$counter/sessions', newSessions);

    setUserVal('/totalSessions', totalSessions + newSessions);

    setUserVal('/totalTime', newTotalTime);
    setUserVal('/counter', counter + 1);
  }
}
