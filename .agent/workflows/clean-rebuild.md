---
description: Full clean + cache wipe + reinstall for Flutter app
---

Use this workflow when you suspect a stale build or cached APK is causing issues (e.g., code changes not appearing on device).

## Steps

// turbo-all

1. Clean Flutter build artifacts:
   ```powershell
   flutter clean
   ```

2. Remove Gradle cache:
   ```powershell
   Remove-Item -Recurse -Force android\.gradle, android\app\build -ErrorAction SilentlyContinue
   ```

3. Get dependencies fresh:
   ```powershell
   flutter pub get
   ```

4. Uninstall the app from device:
   ```powershell
   adb uninstall com.diaspora.delivery.diaspora_delivery
   ```

5. Run the app:
   ```powershell
   flutter run
   ```
