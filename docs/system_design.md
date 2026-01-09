# System Design (SDA)

## Architecture
- Client: Flutter app structured as UI → BLoC → Repository → Services, wired with go_router (navigation) and GetIt (DI).
- Backend: Firebase Auth + Firestore as primary store; Cloudinary for image hosting (unsigned uploads, preset-scoped).
- State: flutter_bloc + equatable; BLoCs own stream subscriptions and cancel on close; UI is passive.
- Data ownership: Firestore collections trips/{id}, requests/{id}, matches/{id}; matches/{id} is the source of truth for an agreement once created.
- Boundaries: UI never touches Firestore; repositories encapsulate schema + invariants; services keep external integrations isolated.

## Data Flow
- Reads: Firestore streams → repositories map to models → BLoCs emit states → UI renders; client-side sorting (by departure/creation time) and lightweight filtering.
- Writes: BLoC intent → repository validates (auth, capacity, status, time) → Firestore write/transaction → BLoC emits success/error; server timestamps used for auditability.
- Concurrency: Firestore transactions serialize conflicting writes; deterministic IDs prevent duplicate matches from concurrent taps.

## Component Responsibilities
- UI layer: display lists/detail, gather intents, show validation or error banners, confirm dialogs before destructive/committal actions.
- BLoCs: orchestrate flows, guard duplicate submissions (intermediate `MatchCreating`), manage streams, expose typed states.
- Repositories: derive IDs, enforce business rules, perform Firestore queries and transactions, map to domain models.
- Services: Cloudinary upload (unsigned preset), Auth helper for uid + profile fields.

## Sequences (key flows)
- Create Match (from trip or request):
  1) UI shows confirmation → dispatch `MatchCreateRequested`.
  2) BLoC emits `MatchCreating` to disable UI and prevent double taps.
  3) Repository: validate trip/request active, capacity sufficient, trip date in future, requester != traveler; call `matchExists`; start transaction → write matches/{matchId} + update requests/{requestId} status to matched + set matchedTripId/matchedTravelerId.
  4) BLoC emits `MatchCreated`; UI navigates or shows toast. Errors propagate with specific messaging (duplicate, inactive, capacity, same user, past trip).
- Listing (trips/requests): Firestore stream subscription → mapped models → BLoC state; UI sorts and filters by status and destination city.

## Data Model Notes
- TripModel: traveler info, origin/destination, departureDate, availableCapacityKg, pricePerKg, status, matchCount.
- RequestModel: requester info, item details, weight, pickup/delivery, price, urgency, status, matchedTripId, matchedTravelerId, images.
- MatchModel: tripId, requestId, traveler/requester info, itemTitle, route, tripDate, agreedPrice, status, participants, timestamps.
- Deterministic IDs: `${tripId}__${requestId}` enabling idempotent creation and O(1) lookup for a pair.

## Matching Logic (Phase 6.5)
- Repository guard: `matchExists(tripId, requestId)` + transaction prevents duplicates and races.
- Traveler flow (Trip → Matching Requests): filter request.deliveryCity == trip.destinationCity; request.status == active; request.weightKg ≤ trip.availableCapacityKg; trip active and upcoming.
- Requester flow (Request → Matching Trips): filter trip.destinationCity == request.deliveryCity; trip.status == active; trip upcoming; availableCapacityKg ≥ request.weightKg.
- Edge handling: duplicate attempts, inactive trip/request, insufficient capacity, trip date passed, same user on both sides → surfaced as typed errors.
- Integrity: matches drive the only path to set a request to matched; cancellations are status changes (no hard deletes), preserving auditability.

## Status Lifecycles
- TripStatus: active → completed/cancelled.
- RequestStatus: active → matched → inProgress/… (legacy) → completed/cancelled; matchedTripId/matchedTravelerId set on match creation.
- MatchStatus: pending → accepted/rejected → confirmed → pickedUp → inTransit → delivered → completed; cancel allowed until delivered.
- Invariants: one request bound to one trip at a time; capacity checked at creation time (no decrement yet); status transitions validated in repository.

## Security/Posture (current and gaps)
- Firestore rules: open/test mode until 2026-02-05. Must tighten to: auth required; per-document ownership checks on trips/requests; matches readable/writeable only by participants; status transitions whitelist.
- Cloudinary: unsigned uploads allow preset abuse; mitigate with size/format limits and monitor usage; move to signed uploads later.
- PII minimization: match docs contain participant names/phones; restrict reads to participants; avoid copying more than needed.
- Abuse risks: spam match creation, rule bypass. Mitigations: client-side rate limits, server-side validation (future callable functions), audit logging.

## Performance & Offline
- Scale expectation: tens to low hundreds of docs per user; client-side sorting is sufficient; no heavy indexes required yet.
- Potential index: destinationCity + status for trip/request matching lists if volume grows.
- Offline: Firestore cache provides basic offline reads; writes rely on connectivity; no bespoke offline queueing.

## Observability
- Client: BlocObserver for state/error logging; Flutter global error handler for crash breadcrumbs.
- Backend: none native to Firestore; consider Cloud Functions front-door for critical writes to centralize validation + logging + metrics.
- Metrics to watch: match creation failure rate by reason, time-to-match, cancellation rate pre- vs post-confirmation.

## Build/Deploy
- Local builds: `flutter build apk --debug`; install via ADB.
- Stale build remediation: `flutter clean`; delete android/.gradle, android/build, android/app/build, build, .dart_tool; rebuild.
- Release hygiene: analyzer clean; smoke tests for match flows; verify route table and DI registrations for new screens.

## Testing/Validation
- Mandatory: `flutter analyze` clean.
- Happy paths: trip creation, request creation, match creation from both sides, pending → accepted flow (where implemented).
- Negative cases: duplicate match attempt blocked; capacity underflow blocked; creating match on past trip blocked; requester == traveler blocked; inactive trip/request blocked.

## Future Enhancements (priority)
- Harden Firestore rules (owner/participant gating, status transition checks, write shape validation).
- Move match creation to callable Cloud Function for centralized validation, rate limiting, and audit logging.
- Capacity management on acceptance/rejection; rollback to active on rejection.
- Notifications (FCM) for match events (created/accepted/rejected).
- Pagination and server-side query filters when volume grows.
