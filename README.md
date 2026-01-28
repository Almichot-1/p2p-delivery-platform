<div align="center">

# Diaspora Delivery — Diaspora Peer Delivery Mobile Application

A peer-to-peer delivery platform that connects diaspora members who want to send items to Ethiopia (**Requesters**) with travelers already going (**Travelers**).

[![Flutter](https://img.shields.io/badge/Flutter-Frontend-blue)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Backend-orange)](https://firebase.google.com/)
[![Node.js](https://img.shields.io/badge/Node.js-Functions-green)](https://nodejs.org/)

</div>

This repository contains:

- **Flutter frontend**: `frontend/`
- **Firebase backend** (Cloud Functions + rules + emulators): `firebase/`
- **Product documentation** (SRS/SDA): `docs/`

---

## Quick links

- App (Flutter): `frontend/README.md`
- Cloud Functions (Firebase): `firebase/functions/`
- SRS/SDA document: `docs/Diaspora_Peer_Delivery_SRS_SDA_v1.0.0.md`

---

## Architecture (high level)

```mermaid
flowchart LR
  U[User] --> A[Flutter App]
  A -->|Auth| FA[Firebase Auth]
  A -->|Data| FS[Cloud Firestore]
  A -->|Media| ST[Firebase Storage]
  A -->|Push| FCM[Firebase Cloud Messaging]
  A -->|Server logic| CF[Cloud Functions]
  CF --> FS
  CF --> ST
```

### Example flow: requester and traveler coordination

```mermaid
sequenceDiagram
  participant R as Requester
  participant App as Flutter App
  participant DB as Firestore
  participant T as Traveler

  R->>App: Create delivery request
  App->>DB: Save request
  T->>App: Browse trips/requests
  App->>DB: Query matching items
  T->>App: Send message / offer
  App->>DB: Create chat + messages
```

---

## Getting started

### Prerequisites

- Node.js (for Firebase emulators / functions)
- Firebase CLI (optional; the repo scripts use `npx firebase-tools`)
- Flutter SDK (Dart >= 3.0)

### Run backend locally (Firebase Emulator Suite)

From the repo root:

```bash
npm run install:functions
npm run serve:backend
```

This starts local emulators for Auth, Firestore, Functions, Storage, Pub/Sub, and the Emulator UI.

### Run the Flutter app

```bash
cd frontend
flutter pub get
flutter run
```

For emulator-friendly Flutter run commands, see `frontend/README.md`.

---

## Repo structure

- `frontend/` — Flutter application
- `firebase/` — Firebase config, security rules, emulators, Cloud Functions
- `docs/` — Requirements and architecture documentation

---

## Contributing

- Keep changes scoped and add tests where practical.
- Follow existing patterns for feature modules (`frontend/lib/features`).
- Prefer running against the emulator suite for development.

---

## License

If you plan to publish this repository, add a LICENSE file and update this section.
