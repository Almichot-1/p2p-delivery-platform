# Requirements

## Scope
- Flutter mobile app for peer-to-peer delivery (Diaspora Delivery).
- Platforms: Android (primary), iOS feasible; backend: Firebase (Auth, Firestore), Cloudinary for images.

## Functional Requirements
1) Authentication
- Email/password login, register, forgot password.
- Persisted session; logout.

2) Profile
- View/update profile (name, phone, photo, country).
- Profile photo upload to Cloudinary (unsigned preset). 

3) Trips (Traveler)
- Create trip: origin, destination, departure date, return date (optional), capacity kg, accepted item types, price/kg (optional), notes.
- List/filter trips (destination, date after).
- View trip details; cancel trip.
- My Trips list.

4) Requests (Requester)
- Create request: title, description, category, weight kg, images (<=5), pickup/delivery addresses, recipient info, preferred delivery date (optional), offered price, urgency flag.
- List/filter requests (delivery city, category).
- View request details; cancel request.
- My Requests list.

5) Matches (Lifecycle)
- List matches for current user; detail view with timeline/status/actions.
- Status transitions validated in repository:
  - pending → accepted/rejected
  - accepted → confirmed
  - confirmed → pickedUp → inTransit → delivered → completed
  - cancel allowed before delivered
- Role rules: traveler performs pickup/transit/delivery; both can confirm/complete; participants only.
- Agreed price editable while pending/accepted.

6) Matches (Creation, Phase 6.5)
- From Trip (Traveler flow):
  - Show matching requests filtered by: deliveryCity == trip.destinationCity, request status == active, request weightKg ≤ trip.availableCapacityKg, trip active and upcoming.
  - Action: “I Can Deliver This” → confirm dialog → create match (status pending) → request becomes matched.
- From Request (Requester flow):
  - Show matching trips filtered by: destinationCity == request.deliveryCity, trip status == active, trip upcoming, trip availableCapacityKg ≥ request.weightKg.
  - Action: “Request This Traveler” → confirm dialog → create match (status pending) → request becomes matched.
- Idempotency: one match per (tripId, requestId); duplicates blocked.
- Validation errors shown to user (capacity, date passed, already matched, duplicate).

7) Navigation
- Tabs: Home, Trips, Requests, Matches, Chat (placeholder), Profile via menu.
- Routes include trip/request create, details, my lists, matches list/detail, matching flows:
  - /trips/:tripId/matching-requests
  - /requests/:requestId/matching-trips

8) Notifications
- Screen scaffold present; push not wired yet.

## Non-Functional Requirements
- Maintain analyzer-clean code; bloc + repository layering; no direct Firestore writes from UI.
- DI via GetIt; routing via go_router; state via flutter_bloc + equatable.
- Image hosting via Cloudinary unsigned preset (MVP); note security caveats.
- Build process: flutter build apk --debug; ADB install/launch for on-device tests.
- Stale build mitigation: flutter clean; remove android/.gradle, android/build, android/app/build, build, .dart_tool; then rebuild.

## Data & Collections (Firestore)
- users
- trips
- requests
- matches
- reviews (placeholder)
- notifications (placeholder)

### Key Fields
- Trip: travelerId/name/photo, origin/destination, departureDate, availableCapacityKg, pricePerKg, status, matchCount.
- Request: requesterId/name/photo, title, category, weightKg, pickup/delivery, offeredPrice, preferredDeliveryDate, isUrgent, status, matchedTripId, matchedTravelerId, imageUrls.
- Match: tripId, requestId, travelerId/name/photo, requesterId/name/photo, itemTitle, route, tripDate, agreedPrice, status, participants, createdAt/updatedAt, confirmedAt/completedAt.

## Security & Privacy
- Current Firestore rules (test mode until 2026-02-05) are wide open — must be tightened; suggested: allow only authenticated users; matches readable by participants; trips/requests at least read-only to authed users; writes limited to owners.
- Cloudinary unsigned uploads: preset can be abused; profile image overwrite risk; acceptable for MVP only.

## Acceptance Criteria (Phase 6.5)
- Traveler can create a match from Trip → Matching Requests with required filters.
- Requester can create a match from Request → Matching Trips with required filters.
- Duplicate (tripId, requestId) creation blocked.
- Request status flips to matched when match created.
- Match appears for both participants with status pending.
- Validation errors are user-visible; no silent failures.
- flutter analyze passes.
