# Diaspora Delivery

A Flutter-based peer-to-peer delivery marketplace that connects travelers with people who need items delivered. Travelers can monetize their extra luggage space while requesters get their items delivered affordably through trusted community members.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Tech Stack](#tech-stack)
- [Getting Started](#getting-started)
- [Configuration](#configuration)
- [Database Schema](#database-schema)
- [Feature Documentation](#feature-documentation)
- [API Reference](#api-reference)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)

## Project Status (Jan 2026)

- Trips, Requests, Matches (lifecycle + creation flows) are implemented and running.
- Chat is implemented per match and is available after match confirmation.
- Notifications UI + repository are implemented; notifications are written by the app during match/chat events (no Cloud Functions required for MVP).
- Firestore rules are currently in test mode (open) and must be tightened before production.

See also:
- docs/requirements.md
- docs/system_design.md

## Overview

Diaspora Delivery solves the problem of expensive international shipping by leveraging travelers who have extra luggage capacity. The platform enables:

- **Travelers**: Post upcoming trips with available capacity and earn money by delivering items
- **Requesters**: Post delivery requests for items they need transported and find matching travelers

The app handles the entire lifecycle from posting trips/requests, matching, negotiation, delivery tracking, and completion.

## Features

### Authentication
- Email/password registration and login
- Password reset via email
- Persistent session management
- Profile photo upload

### Trips (Traveler Features)
- Create trips with origin/destination cities
- Set available capacity (kg) and price per kg
- Specify accepted item types (Documents, Electronics, Clothing, Food, Medicine, Other)
- Direction toggle (Ethiopia → Abroad or Abroad → Ethiopia)
- City picker with common cities dropdown + manual entry option
- View and manage your trips
- See matching requests for your trips
- Trip status management (active, completed, cancelled)

### Requests (Requester Features)
- Simplified single-form request creation
- Item details: title, category, weight, description
- Pickup and delivery location with city picker
- Recipient information (name, phone)
- Optional: preferred delivery date, offered price, urgency flag
- Multi-image upload (up to 5 photos)
- View and manage your requests
- See matching trips for your requests

### Smart Matching
- Matching lists are computed based on:
  - Route compatibility (origin/destination city)
  - Trip must be upcoming and active
  - Request must be active
  - Capacity availability (request weight ≤ trip capacity)
- Match request workflow with accept/reject
- Agreed price negotiation

Planned (not guaranteed in current build):
- Item type acceptance filtering
- Deeper date compatibility (e.g., preferred delivery date vs trip departure)

### Match Lifecycle
Status progression:
```
pending → accepted → confirmed → pickedUp → inTransit → delivered → completed
                ↘ rejected
        (cancellation available until delivered)
```

### Real-time Chat
- In-app messaging between matched users
- Text and image messages
- Message read receipts
- Edit messages (within 12 hours)
- Delete messages (within 12 hours)
- System messages for status updates
- Chat only available after match confirmation

### Notifications
- In-app notifications stored in Firestore and shown in the Notifications screen
- Notification types include match requests, accept/reject/confirm, new messages, and status updates
- Mark as read (single/all)
- Swipe to delete
- Clear all notifications

Note: Push notifications (FCM) are optional and may require additional backend setup.

### Search
- Search trips by destination, city, traveler name
- Search requests by title, city, requester name
- Tabbed interface for trips and requests

### Profile
- View and edit profile information
- Profile photo upload with cropping
- User ratings display
- Settings management

## Architecture

The app follows a clean layered architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  (Screens, Widgets, UI Components)                          │
├─────────────────────────────────────────────────────────────┤
│                      BLoC Layer                              │
│  (Business Logic, State Management)                         │
├─────────────────────────────────────────────────────────────┤
│                    Repository Layer                          │
│  (Data Operations, Business Rules)                          │
├─────────────────────────────────────────────────────────────┤
│                     Services Layer                           │
│  (Firebase, Cloudinary, External APIs)                      │
└─────────────────────────────────────────────────────────────┘
```

### Key Patterns
- **State Management**: flutter_bloc for reactive state management
- **Dependency Injection**: GetIt for service locator pattern
- **Routing**: go_router for declarative navigation
- **Real-time Data**: Firestore streams for live updates

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # MaterialApp configuration
├── config/
│   ├── di.dart              # Dependency injection setup
│   └── routes.dart          # Route definitions
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── cloudinary_constants.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   └── cloudinary_service.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   └── app_theme.dart
│   ├── utils/
│   │   └── time_ago.dart
│   └── widgets/
│       ├── cached_image.dart
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── section_header.dart
└── features/
    ├── auth/
    │   ├── bloc/
    │   │   ├── auth_bloc.dart
    │   │   ├── auth_event.dart
    │   │   └── auth_state.dart
    │   ├── data/
    │   │   ├── models/user_model.dart
    │   │   └── repositories/auth_repository.dart
    │   └── presentation/
    │       └── screens/
    │           ├── login_screen.dart
    │           ├── register_screen.dart
    │           ├── forgot_password_screen.dart
    │           ├── onboarding_screen.dart
    │           └── splash_screen.dart
    ├── chat/
    │   ├── bloc/
    │   │   ├── chat_bloc.dart
    │   │   ├── chat_event.dart
    │   │   └── chat_state.dart
    │   ├── data/
    │   │   ├── models/message_model.dart
    │   │   └── repositories/chat_repository.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── chat_screen.dart
    │       │   └── conversations_screen.dart
    │       └── widgets/
    │           ├── chat_input.dart
    │           ├── conversation_tile.dart
    │           └── message_bubble.dart
    ├── home/
    │   └── presentation/
    │       ├── screens/
    │       │   ├── home_screen.dart
    │       │   └── search_screen.dart
    │       └── widgets/
    │           └── home_header.dart
    ├── matches/
    │   ├── bloc/
    │   │   ├── match_bloc.dart
    │   │   ├── match_event.dart
    │   │   └── match_state.dart
    │   ├── data/
    │   │   ├── models/match_model.dart
    │   │   └── repositories/match_repository.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── matches_screen.dart
    │       │   └── match_details_screen.dart
    │       └── widgets/
    │           ├── match_card.dart
    │           └── match_status_timeline.dart
    ├── notifications/
    │   ├── bloc/
    │   │   ├── notification_bloc.dart
    │   │   ├── notification_event.dart
    │   │   └── notification_state.dart
    │   ├── data/
    │   │   ├── models/notification_model.dart
    │   │   └── repositories/notification_repository.dart
    │   └── presentation/
    │       └── screens/
    │           └── notifications_screen.dart
    ├── profile/
    │   ├── bloc/
    │   │   ├── profile_bloc.dart
    │   │   ├── profile_event.dart
    │   │   └── profile_state.dart
    │   ├── data/
    │   │   └── repositories/profile_repository.dart
    │   └── presentation/
    │       └── screens/
    │           ├── profile_screen.dart
    │           ├── edit_profile_screen.dart
    │           └── settings_screen.dart
    ├── requests/
    │   ├── bloc/
    │   │   ├── request_bloc.dart
    │   │   ├── request_event.dart
    │   │   └── request_state.dart
    │   ├── data/
    │   │   ├── models/request_model.dart
    │   │   └── repositories/request_repository.dart
    │   └── presentation/
    │       ├── screens/
    │       │   ├── requests_list_screen.dart
    │       │   ├── create_request_screen.dart
    │       │   ├── request_details_screen.dart
    │       │   ├── my_requests_screen.dart
    │       │   └── matching_trips_screen.dart
    │       └── widgets/
    │           └── request_card.dart
    └── trips/
        ├── bloc/
        │   ├── trip_bloc.dart
        │   ├── trip_event.dart
        │   └── trip_state.dart
        ├── data/
        │   ├── models/trip_model.dart
        │   └── repositories/trip_repository.dart
        └── presentation/
            ├── screens/
            │   ├── trips_list_screen.dart
            │   ├── create_trip_screen.dart
            │   ├── trip_details_screen.dart
            │   ├── my_trips_screen.dart
            │   └── matching_requests_screen.dart
            └── widgets/
                └── trip_card.dart
```

## Tech Stack

### Frontend
- **Flutter** 3.x - Cross-platform UI framework
- **Dart** >=3.2.0 - Programming language

### State Management & Architecture
- **flutter_bloc** ^8.1.4 - State management
- **equatable** ^2.0.5 - Value equality
- **get_it** ^7.6.7 - Dependency injection
- **go_router** ^13.2.0 - Navigation

### Backend Services
- **Firebase Auth** ^4.17.0 - Authentication
- **Cloud Firestore** ^4.15.0 - NoSQL database
- **Firebase Messaging** ^14.7.20 - Push notifications

### Image Handling
- **Cloudinary** - Image hosting (unsigned uploads)
- **image_picker** ^1.0.7 - Image selection
- **image_cropper** ^11.0.0 - Image cropping
- **cached_network_image** ^3.3.1 - Image caching

### Utilities
- **http** ^1.2.0 - HTTP client
- **intl** ^0.19.0 - Internationalization
- **uuid** ^4.3.3 - UUID generation
- **shared_preferences** ^2.2.2 - Local storage
- **shimmer** ^3.0.0 - Loading effects

## Getting Started

### Prerequisites
- Flutter SDK (>=3.2.0)
- Android Studio / Xcode
- Firebase project
- Cloudinary account

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Almichot-1/Diaspora_mb.git
cd Diaspora_mb
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
   - Create a Firebase project
   - Add Android/iOS apps
   - Download `google-services.json` (Android) to `android/app/`
   - Download `GoogleService-Info.plist` (iOS) to `ios/Runner/`

4. Run the app:
```bash
flutter run
```

### Build Commands

Debug APK:
```bash
flutter build apk --debug
```

Release APK:
```bash
flutter build apk --release
```

Install on device:
```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## Configuration

### Firebase Setup

Required Firebase services:
- **Authentication**: Email/password provider enabled
- **Cloud Firestore**: Database for all app data
- **Firebase Messaging**: Push notifications (optional)

Firestore security rules should be configured to:
- Allow authenticated users to read/write their own data
- Allow public read access to trips and requests
- Restrict match operations to participants only

### Cloudinary Setup

1. Create a Cloudinary account
2. Create an unsigned upload preset named `diaspora_unsigned`
3. Enable dynamic folders in preset settings

Configure via dart-define:
```bash
flutter run \
  --dart-define=CLOUDINARY_CLOUD_NAME=your_cloud_name \
  --dart-define=CLOUDINARY_UPLOAD_PRESET=your_preset
```

Image folders:
- Profile images: `diaspora/profiles`
- Chat images: `diaspora/chats`
- Request images: `requests/<requestId>`

## Database Schema

### Firestore Collections

#### users
```javascript
{
  uid: string,
  email: string,
  fullName: string,
  photoUrl: string | null,
  phone: string | null,
  bio: string | null,
  rating: number,
  reviewCount: number,
  tripsCompleted: number,
  requestsCompleted: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### trips
```javascript
{
  id: string,
  travelerId: string,
  travelerName: string,
  travelerPhoto: string | null,
  travelerRating: number,
  originCity: string,
  originCountry: string,
  destinationCity: string,
  destinationCountry: string,
  departureDate: timestamp,
  returnDate: timestamp | null,
  availableCapacityKg: number,
  pricePerKg: number | null,
  acceptedItemTypes: string[],
  notes: string | null,
  status: 'active' | 'completed' | 'cancelled',
  matchCount: number,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### requests
```javascript
{
  id: string,
  requesterId: string,
  requesterName: string,
  requesterPhoto: string | null,
  requesterRating: number,
  title: string,
  description: string,
  category: 'documents' | 'electronics' | 'clothing' | 'food' | 'medicine' | 'other',
  weightKg: number,
  imageUrls: string[],
  pickupCity: string,
  pickupCountry: string,
  pickupAddress: string,
  deliveryCity: string,
  deliveryCountry: string,
  deliveryAddress: string,
  recipientName: string,
  recipientPhone: string,
  preferredDeliveryDate: timestamp | null,
  offeredPrice: number | null,
  isUrgent: boolean,
  status: 'active' | 'matched' | 'completed' | 'cancelled',
  matchedTripId: string | null,
  matchedTravelerId: string | null,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### matches
```javascript
{
  id: string,  // Format: {tripId}__{requestId}
  tripId: string,
  requestId: string,
  travelerId: string,
  travelerName: string,
  travelerPhoto: string | null,
  requesterId: string,
  requesterName: string,
  requesterPhoto: string | null,
  itemTitle: string,
  route: string,
  tripDate: timestamp,
  agreedPrice: number | null,
  status: 'pending' | 'accepted' | 'rejected' | 'confirmed' | 'pickedUp' | 'inTransit' | 'delivered' | 'completed' | 'cancelled',
  participants: string[],  // [travelerId, requesterId]
  lastMessage: string | null,
  lastMessageAt: timestamp | null,
  confirmedAt: timestamp | null,
  completedAt: timestamp | null,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### matches/{matchId}/messages (subcollection)
```javascript
{
  id: string,
  matchId: string,
  senderId: string,
  senderName: string,
  content: string,
  type: 'text' | 'image' | 'system',
  imageUrl: string | null,
  isRead: boolean,
  isEdited: boolean,
  editedAt: timestamp | null,
  createdAt: timestamp
}
```

#### notifications
```javascript
{
  id: string,
  userId: string,
  type: 'matchRequest' | 'matchAccepted' | 'matchRejected' | 'matchConfirmed' | 'newMessage' | 'statusUpdate' | 'system',
  title: string,
  body: string,
  isRead: boolean,
  matchId: string | null,
  tripId: string | null,
  requestId: string | null,
  senderId: string | null,
  senderName: string | null,
  senderPhoto: string | null,
  data: map | null,
  createdAt: timestamp
}
```

#### reviews
```javascript
{
  id: string,
  matchId: string,
  reviewerId: string,
  revieweeId: string,
  rating: number,  // 1-5
  comment: string | null,
  createdAt: timestamp
}
```

## Feature Documentation

### Match Creation Flow

1. Requester browses trips or views matching trips for their request
2. Requester taps "Request Match" on a compatible trip
3. System creates match with status `pending`
4. Traveler receives notification
5. Traveler can accept or reject
6. If accepted, both parties can confirm and chat becomes available
7. Delivery tracking through status updates

### Chat System

- Chat is only available for matches with status >= `confirmed`
- Messages support text and images
- Edit/delete available within 12 hours of sending
- System messages auto-generated for status changes
- Real-time updates via Firestore streams

### Notification System

Notifications are created automatically when:
- Match request is created (notifies traveler)
- Match is accepted (notifies requester)
- Match is rejected (notifies requester)
- Delivery status changes (notifies both parties)

## API Reference

### BLoC Events

#### AuthBloc
- `AuthCheckRequested` - Check current auth state
- `AuthLoginRequested(email, password)` - Login
- `AuthRegisterRequested(email, password, fullName)` - Register
- `AuthLogoutRequested` - Logout
- `AuthPasswordResetRequested(email)` - Reset password

#### TripBloc
- `TripsLoadRequested` - Load all active trips
- `MyTripsLoadRequested(userId)` - Load user's trips
- `TripCreateRequested(trip)` - Create trip
- `TripUpdateRequested(trip)` - Update trip
- `TripCancelRequested(tripId)` - Cancel trip

#### RequestBloc
- `RequestsLoadRequested` - Load all active requests
- `MyRequestsLoadRequested(userId)` - Load user's requests
- `RequestCreateRequested(request, images)` - Create request
- `RequestUpdateRequested(request)` - Update request
- `RequestCancelRequested(requestId)` - Cancel request

#### MatchBloc
- `MatchesLoadRequested(userId)` - Load user's matches
- `MatchDetailsRequested(matchId)` - Load match details
- `MatchCreateRequested(...)` - Create match
- `MatchAcceptRequested(matchId)` - Accept match
- `MatchRejectRequested(matchId)` - Reject match
- `MatchConfirmRequested(matchId)` - Confirm match
- `MatchStatusUpdateRequested(matchId, status)` - Update status
- `MatchCancelRequested(matchId)` - Cancel match

#### ChatBloc
- `ChatLoadRequested(matchId)` - Load chat messages
- `ChatSendMessageRequested(matchId, content)` - Send text
- `ChatSendImageRequested(matchId, image)` - Send image
- `ChatEditMessageRequested(matchId, messageId, content)` - Edit message
- `ChatDeleteMessageRequested(matchId, messageId)` - Delete message
- `ChatMarkAsReadRequested(matchId)` - Mark messages read

#### NotificationBloc
- `NotificationsLoadRequested(userId)` - Load notifications
- `NotificationMarkAsReadRequested(notificationId)` - Mark read
- `NotificationMarkAllAsReadRequested(userId)` - Mark all read
- `NotificationDeleteRequested(notificationId)` - Delete
- `NotificationDeleteAllRequested(userId)` - Delete all

## Troubleshooting

### Stale UI after code changes

```bash
flutter clean
flutter pub get
```

Full clean (Windows PowerShell):
```powershell
flutter clean
Remove-Item -Recurse -Force .dart_tool, build -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force android\.gradle, android\build, android\app\build -ErrorAction SilentlyContinue
flutter pub get
flutter build apk --debug
```

Full clean (macOS/Linux):
```bash
flutter clean
rm -rf .dart_tool build android/.gradle android/build android/app/build
flutter pub get
flutter build apk --debug
```

Reinstall app:
```bash
adb uninstall com.diaspora.delivery.diaspora_delivery
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

### Cloudinary uploads not working

1. Verify cloud name matches your account
2. Ensure upload preset is set to "unsigned"
3. Check preset allows dynamic folders
4. Verify network connectivity

### Firebase errors

1. Ensure `google-services.json` is in `android/app/`
2. Check Firebase project has required services enabled
3. Verify package name matches Firebase app configuration

### Chat not available

Chat is only enabled for matches with status `confirmed` or later. Ensure:
1. Match has been accepted by traveler
2. Match has been confirmed by both parties

## Security Considerations

### Current MVP Limitations

1. **Unsigned Cloudinary uploads**: Anyone with the preset can upload. Profile photos use deterministic public_id (user's uid), which could be overwritten by malicious actors.

2. **Client-side validation**: Most validation happens client-side. Firestore security rules should be properly configured for production.

3. **Firestore rules currently in test mode**: If your Firestore rules are in "test mode" (wide open), any user can read/write data. Tighten rules before sharing the app.

### Recommended for Production

1. Move to signed Cloudinary uploads via backend proxy
2. Implement proper Firestore security rules
3. Add rate limiting
4. Implement user verification/KYC
5. Add payment integration with escrow
6. Implement dispute resolution system

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Contact

For questions or support, please contact the development team.
