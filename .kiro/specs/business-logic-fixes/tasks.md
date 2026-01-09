# Business Logic Fixes - Task List

## Overview
Fix critical business logic issues identified in the Diaspora Delivery app.

## Tasks

- [x] 1. Request Status Rollback on Match Rejection
  - When traveler rejects a match, revert request.status to 'active'
  - Clear request.matchedTripId and matchedTravelerId
  - Use transaction for atomicity
  - _Files: match_repository.dart_

- [x] 2. Request Status Rollback on Match Cancellation
  - When match is cancelled, revert request.status to 'active'
  - Clear request.matchedTripId and matchedTravelerId
  - Use transaction for atomicity
  - _Files: match_repository.dart_

- [x] 3. Trip Capacity Deduction on Match Creation
  - Deduct request.weightKg from trip.availableCapacityKg when match is created
  - Add to existing transaction in createMatch()
  - _Files: match_repository.dart_

- [x] 4. Trip Capacity Restoration on Match Rejection/Cancellation
  - Restore capacity when match is rejected or cancelled
  - Fetch request weight and add back to trip capacity
  - _Files: match_repository.dart_

- [x] 5. Chat Backend Validation
  - Verify match exists and status is confirmed+
  - Verify sender is a participant in the match
  - Add validation to sendMessage() and sendImageMessage()
  - _Files: chat_repository.dart_

- [x] 6. Fix Destination City/Country Parameter Confusion
  - Renamed parameter from destinationCountry to destination
  - Added case-insensitive comparison
  - _Files: matching_trips_screen.dart, trip_repository.dart, trip_bloc.dart, trip_event.dart, trips_list_screen.dart_

- [x] 7. Consolidate Trip Date Validation
  - Remove duplicate trip date validation in createMatch()
  - Use single source of truth (Firestore tripData) with fallback
  - _Files: match_repository.dart_

- [x] 8. Add Negative/Zero Weight Validation
  - Validate weight > 0 and <= 100 in request creation
  - Validate capacity > 0 and <= 100 in trip creation
  - _Files: request_repository.dart, trip_repository.dart_

- [x] 9. Add Price Validation Improvements
  - Check for negative prices
  - Add reasonable upper bound (100,000)
  - _Files: match_repository.dart_

- [x] 10. Add System Messages on Status Changes
  - Send system message when match status changes
  - Added ChatRepository to MatchBloc
  - System messages sent for: accept, confirm, pickedUp, inTransit, delivered, completed, cancelled
  - _Files: match_bloc.dart, di.dart_

## Notes
- All tasks completed ✓
