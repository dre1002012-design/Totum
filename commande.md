*(Depuis le module Respiration (13/08/2026), le flag `--wasm` est nécessaire sur le web : le moteur audio `flutter_soloud` a besoin de `SharedArrayBuffer`, indisponible sans lui — sans `--wasm`, le module reste muet sans erreur visible.)*

* **Appli local:**

cd C:\\Users\\Alexa\\Apps\\Totum
flutter clean
flutter pub get
flutter run -d chrome --wasm

* **Wepp APP:**

flutter clean
flutter pub get
flutter build web --wasm
firebase deploy --only hosting

* **Local Tel:**

flutter clean
flutter pub get
flutter build apk --release
C:\Users\Alexa\Apps\Totum\build\app\outputs\flutter-apk

* **Play store:**

flutter clean
flutter pub get
flutter build appbundle --release
C:\Users\Alexa\Apps\Totum\build\app\outputs\bundle\release


* **Logo:**

cd C:\\Users\\Alexa\\hybrid\_flow\_training
flutter clean
flutter pub get
flutter pub run flutter\_launcher\_icons:main

* **Récapitulatif**

\# Lancer l'application en local (Chrome)
flutter run -d chrome --wasm

\# Build Web
flutter build web --wasm

\# Déploiement Firebase
firebase deploy --only hosting

\# APK Release
flutter build apk --release

\# Android App Bundle (Play Store)
flutter build appbundle --release







* **Mis a jour dossier git hub**

git commit -a -m "Synchronisation rapide de tous les fichiers" \&\& git push

