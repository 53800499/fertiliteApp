# Sécurité Mobile, Biométrie & Chiffrement Local
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Verrouillage Biométrique (`local_auth`)

L'application protège l'accès physique à l'écran via l'API biométrique de la plateforme :

```dart
// lib/core/security/biometrics_helper.dart
import 'package:local_auth/local_auth.dart';

class BiometricsHelper {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> authenticate() async {
    final canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    if (!canAuthenticate) return true;

    try {
      return await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à vos données de cycle',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
```

---

## 2. Protection de la Vue dans le Sélecteur d'Applications

Sur iOS (`AppDelegate.swift`) et Android (`MainActivity.kt`), un filtre de flou opaque ou le drapeau `FLAG_SECURE` est activé dès que l'application passe en arrière-plan afin d'empêcher les captures d'écran indiscrètes dans le multitâche.
