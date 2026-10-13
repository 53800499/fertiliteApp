# Guide de Compilation & Distribution Mobile (Fastlane)
## Application mobile d'estimation intelligente de la fertilité (FertiliteApp)

---

## 1. Automatisation avec Fastlane

Fichier `Fastfile` configuré pour automatiser la signature et le téléversement vers TestFlight et Google Play Internal App Sharing :

```ruby
default_platform(:android)

platform :android do
  desc "Build & deploy release to Google Play Internal"
  lane :internal do
    gradle(task: "clean bundleRelease")
    upload_to_play_store(
      track: 'internal',
      release_status: 'draft',
      skip_upload_metadata: true
    )
  end
end

platform :ios do
  desc "Build & deploy release to TestFlight"
  lane :beta do
    match(type: "appstore")
    build_app(scheme: "Runner")
    upload_to_testflight
  end
end
```
