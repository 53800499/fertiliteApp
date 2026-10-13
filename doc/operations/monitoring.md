# Monitoring Applicatif Mobile & Crash Reporting (Sentry)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Intégration Sécurisée de Sentry Flutter

Pour capter les plantages sans enregistrer de données médicales privées :

```dart
// lib/main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = 'https://sentry_key@sentry.io/project_id';
      options.tracesSampleRate = 0.2; // Échantillonnage de 20%
      options.sendDefaultPii = false; // Interdiction formelle de collecter les données d'identité
      options.beforeSend = (event, {hint}) {
        // Filtrage supplémentaire : suppression des miettes de pain (breadcrumbs) contenant des routes intimes
        return event;
      };
    },
    appRunner: () => runApp(const FertiliteApp()),
  );
}
```