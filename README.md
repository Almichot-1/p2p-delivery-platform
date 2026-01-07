# diaspora_delivery

Diaspora Delivery is a Flutter app for a peer-to-peer delivery marketplace:

- **Trips**: travelers post upcoming trips and available capacity.
- **Requests**: requesters post items they want delivered (optionally with photos).

This repo uses a simple layered architecture (UI → BLoC → Repository → Services) with dependency injection via GetIt and routing via go_router.

## Features (current)

- Auth: email/password login/register (Firebase Auth)
- Profile: edit profile + profile photo upload
- Trips: list, filters, create/edit, details, cancel, My Trips
- Requests: list + filters, create/edit (multi-step), details, cancel, My Requests
- Notifications screen scaffold
- Matches + Chat screens are present as minimal stubs (placeholders were removed from the project)

## Architecture

- **Routing**: go_router in `lib/config/routes.dart`
- **DI**: GetIt registrations in `lib/config/di.dart`
- **State management**: flutter_bloc BLoCs per feature
- **Data**:
	- Firebase Auth + Cloud Firestore
	- Cloudinary (unsigned uploads) for images

## Configuration

### Firebase

The app uses:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_messaging`

To enable Firebase for Android, ensure the correct Firebase config files are present:

- `android/app/google-services.json`

If Firebase is missing or misconfigured for the current build, the app may boot but auth-related flows can fail or show configuration warnings.

### Cloudinary

Cloudinary is used for image hosting.

**How uploads work**

- Images are picked locally first.
- On submit (create/edit), the app uploads images to Cloudinary and stores returned `secure_url` values in Firestore.

**Preset/config (current code defaults)**

- Cloud name: `dicohicdc`
- Upload preset: `diaspora_unsigned`
- Uploads are **Unsigned** (MVP)
- Folder mode should allow **dynamic folders** (the app sends `folder` per upload)

**Where images appear in Cloudinary Media Library**

- Profile images: `diaspora/profiles`
- Chat images: `diaspora/chats`
- Request images (current implementation): `requests/<requestId>`

Note: there are folder constants in `lib/core/constants/cloudinary_constants.dart`, but request uploads are currently using a `requests/<id>` folder set by the repository.

**Recommended: configure via --dart-define**

```bash
flutter run \
	--dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME \
	--dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

Same for builds:

```bash
flutter build apk --debug \
	--dart-define=CLOUDINARY_CLOUD_NAME=YOUR_CLOUD_NAME \
	--dart-define=CLOUDINARY_UPLOAD_PRESET=YOUR_UNSIGNED_PRESET
```

## Development

### Requirements

- Flutter SDK (Dart SDK `>= 3.2.0 < 4.0.0`)
- Android Studio / Android SDK (for Android builds)

### Install dependencies

```bash
flutter pub get
```

### Run on device/emulator

```bash
flutter run
```

### Build + install a debug APK (Android)

```bash
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
adb shell am start -n com.diaspora.delivery.diaspora_delivery/.MainActivity
```

## Troubleshooting

### Requests tab still shows an old UI after rebuilding

If the app UI looks "stuck" (e.g., an older tab layout/strings show up even though source changed), it can be caused by stale build artifacts.

Recommended cleanup steps:

```bash
flutter clean
flutter pub get
```

If that’s not enough, also wipe Android/Gradle build caches and rebuild:

```bash
rm -rf android/.gradle android/app/build android/build
flutter build apk --debug
```

Then uninstall/reinstall the app:

```bash
adb uninstall com.diaspora.delivery.diaspora_delivery
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Cloudinary uploads not visible

Common causes:

- Looking at the wrong Cloudinary account (cloud name mismatch)
- Upload preset is not configured for unsigned uploads
- Images were never submitted (picked locally but request not created)
- Folder expectation mismatch (requests currently upload under `requests/<requestId>`)

## Security / MVP caveat

### Cloudinary uploads are unsigned

This app currently uses **unsigned** Cloudinary uploads (an upload preset) for image hosting.

Implications:

- If the upload preset is leaked/abused, uploads can be performed by anyone who has the preset.
- Profile photos use a deterministic `public_id` equal to the Firebase Auth `uid`, which means a malicious uploader with the preset could overwrite another user's profile image if they know the `uid`.

This is acceptable for MVP only. Do not treat Cloudinary URLs/uploads as a security boundary.

### Hardening (future)

- Move to **signed uploads** (server-generated signature) or a backend proxy that enforces authorization.
- Restrict/rotate the unsigned preset (formats, size limits, rate limits, overwrite restrictions).
