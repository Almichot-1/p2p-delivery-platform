# diaspora_delivery

A new Flutter project.

## Technical notes (MVP caveat)

### Cloudinary preset/config (current)

- Preset name: `diaspora_unsigned`
- Signing mode: **Unsigned**
- Folder mode: **Dynamic folders** (the app sends `folder` per upload)
- Base folder: `diaspora` (the app uses `diaspora/profiles`, `diaspora/requests`, `diaspora/chats`)

### Cloudinary uploads are unsigned

This app currently uses **unsigned** Cloudinary uploads (an upload preset) for image hosting.

Implications:

- If the upload preset is leaked/abused, uploads can be performed by anyone who has the preset.
- Profile photos currently use a deterministic `public_id` equal to the Firebase Auth `uid`, which means a malicious uploader with the preset could overwrite another user's profile image if they know the `uid`.

This is acceptable for MVP only. Do not treat Cloudinary URLs/uploads as a security boundary.

### TODO (Phase 8+ hardening)

- Move to **signed uploads** (server-generated signature) or a **backend proxy** that enforces ownership/authorization per user.
- Rotate/restrict the unsigned preset as much as possible until signed uploads exist (limit allowed formats, size, rate limits, and avoid broad overwrite capabilities).

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
