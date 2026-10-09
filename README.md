# Ember - offline calorie tracker (Flutter)

Build locally (Flutter 3.24.5, JDK 17):
    flutter create --platforms=android --project-name calorie_counter .
    flutter pub get
    dart run flutter_launcher_icons
    flutter build apk --release

Or push to GitHub: the workflow in .github/workflows builds the APK
(Actions tab -> latest run -> Artifacts -> ember-apk).
