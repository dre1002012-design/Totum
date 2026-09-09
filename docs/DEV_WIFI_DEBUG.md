# Débogage Android sans câble USB (débogage sans fil / ADB over Wi-Fi)

Contexte : le câble USB d'Alex n'est pas détecté par l'ordinateur pour son téléphone Android — le flux normal (`flutter run -d <appareil>`) est donc indisponible, forçant un cycle lent à chaque test (`flutter build apk --release` → transfert via Google Drive → installation manuelle → désinstallation de l'ancienne version). Le débogage sans fil Android élimine ce détour : `flutter run` détecte et installe directement sur le téléphone via le Wi-Fi, sans câble.

Prérequis : téléphone et ordinateur sur le **même réseau Wi-Fi**. Android 11 ou plus récent (le pairing par QR code/code n'existe pas avant).

## 1. Activer le débogage sans fil sur le téléphone

1. `Paramètres` → `À propos du téléphone` → taper 7 fois sur `Numéro de build` pour activer les `Options pour les développeurs` (si pas déjà fait).
2. `Paramètres` → `Options pour les développeurs` → activer `Débogage USB` (nécessaire même en sans-fil, pour l'appairage initial) et `Débogage sans fil`.
3. Ouvrir `Débogage sans fil` → `Coupler l'appareil avec un code QR` (ou `Coupler l'appareil avec un code d'appairage`).

## 2. Coupler l'ordinateur (une seule fois)

Depuis un terminal, sur l'ordinateur :

```
adb pair <adresse-ip>:<port-appairage>
```

(l'adresse IP et le port d'appairage sont affichés sur l'écran `Débogage sans fil` du téléphone, dans l'écran de couplage). Entrer le code à 6 chiffres affiché sur le téléphone quand `adb` le demande.

Si `adb` n'est pas reconnu dans le terminal : il est fourni avec le SDK Android installé par Flutter, généralement dans `%LOCALAPPDATA%\Android\sdk\platform-tools` — soit ajouter ce dossier au `PATH`, soit lancer la commande avec le chemin complet (`"%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe" pair ...`).

## 3. Se connecter (à chaque session de travail)

L'écran `Débogage sans fil` du téléphone affiche aussi une **adresse IP et un port de connexion** (différent du port d'appairage) :

```
adb connect <adresse-ip>:<port-connexion>
```

Vérifier que ça a marché :

```
adb devices
```

Le téléphone doit apparaître dans la liste (`<ip>:<port>  device`).

## 4. Lancer l'app directement dessus

```
flutter devices
flutter run -d <id-appareil-affiché>
```

Compile, installe et lance en une seule commande, avec le code source actuel garanti (fini le détour Drive) — et permet aussi le hot reload (`r` dans le terminal) pour itérer en quelques secondes sur un changement d'UI, sans même recompiler entièrement.

## Notes

- La connexion Wi-Fi se coupe si le téléphone redémarre ou quitte le réseau — il suffit de refaire l'étape 3 (`adb connect`, pas besoin de re-coupler avec `adb pair` à chaque fois, sauf changement de réseau/téléphone).
- Pour tester spécifiquement un **build release** (comportement le plus proche de la Play Store) plutôt que debug : `flutter run --release -d <id-appareil>`.
- Si `adb pair`/`adb connect` échouent alors que le Wi-Fi est bien le même réseau : vérifier qu'aucun VPN n'est actif sur l'un des deux appareils, et qu'aucun pare-feu ne bloque le sous-réseau local.
