# Intelligent ERP - Agent Development Rules & Guidelines

## 1. Android APK Build Rules (CRITICAL)
- **Target Audience / Devices**: The app is strictly designed for **physical mobile phones only** (both legacy 32-bit phones and modern 64-bit phones). It is **NOT** for desktop/laptop PC emulators.
- **Architectures**:
  - `armeabi-v7a` (Old / legacy mobile phones)
  - `arm64-v8a` (New / modern mobile phones)
  - **EXCLUDE `x86_64` and `x86`** (Desktop/emulator binaries must never be packaged).
- **Target APK Size**: Approximately **~40 MB** (as specified in `version.json` and GitHub release `v.1.1.0`). Never build a fat 62+ MB APK that bundles PC emulator binaries.
- **Standard Build Command**:
  ```bash
  flutter build apk --release --target-platform android-arm,android-arm64
  ```
  Or via the npm script:
  ```bash
  npm run build:apk
  ```
- **Desktop Output Location**:
  Whenever building or updating the release APK, always copy the compiled APK to:
  ```bash
  cp build/app/outputs/flutter-apk/app-release.apk /Users/saryankhan/Desktop/Intelligent.ERP.apk
  ```

## 2. UI / UX Rules
- In the student portal backlogs view (`StudentBacklogsScreen`), do not show alarming red alert boxes or "Active Backlogs" warning banners. Present the pending subjects cleanly and directly.
