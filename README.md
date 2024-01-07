# 8096-attendance-client
The client for the attendance app used by FRC team 8096, Cache Money.

To run locally:
* Clone the repo
* Ensure the information in `.firebaserc` and `lib/firebase_options.dart` match the Firebase project
* Ensure you have the flutter sdk installed
* Run `flutter build web --base-href "/build/web/"`
* Start a local server, e.g. by running `python3 -m http.server 8000` (you may need to run `pip install http`)
* Navigate to the appropriate link. In the above example, navigate to `http://localhost:8000/build/web/`