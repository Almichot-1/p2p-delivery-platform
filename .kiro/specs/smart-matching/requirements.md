# Requirements Document: Smart Matching Algorithm

## Introduction

The Diaspora Delivery app currently shows all active trips and requests without filtering for compatibility. This feature implements intelligent matching that only displays compatible trips/requests based on destination, capacity, date, and status criteria.

## Glossary

- **Traveler**: A user offering to carry items on their trip
- **Requester**: A user (diaspora) needing an item delivered
- **Trip**: A traveler's journey with available capacity
- **Request**: A requester's delivery need
- **Match**: A connection between a trip and request
- **Smart_Matching**: Filtering algorithm that shows only compatible trips/requests
- **Destination_City**: The final destination city for trip or delivery
- **Available_Capacity**: Remaining weight capacity (kg) on a trip
- **Weight**: The weight (kg) of the requested item
- **Active_Status**: Trip or request is available for matching (not cancelled, not already matched)
- **Upcoming_Trip**: Trip departure date is in the future

## Requirements

### Requirement 1: Smart Matching for Travelers

**User Story:** As a traveler, I want to see only requests that match my trip destination and capacity, so that I can quickly find deliveries I can actually fulfill.

#### Acceptance Criteria

1. WHEN a traveler views matching requests for their trip, THE System SHALL display only requests where the delivery city matches the trip destination city
2. WHEN displaying matching requests, THE System SHALL show only requests with active status
3. WHEN displaying matching requests, THE System SHALL show only requests where the weight is less than or equal to the trip's available capacity
4. WHEN a traveler's trip is not active, THE System SHALL prevent viewing matching requests
5. WHEN a traveler's trip date has passed, THE System SHALL prevent viewing matching requests

### Requirement 2: Smart Matching for Requesters

**User Story:** As a requester, I want to see only travelers going to my delivery destination with sufficient capacity, so that I can find suitable delivery options.

#### Acceptance Criteria

1. WHEN a requester views matching trips for their request, THE System SHALL display only trips where the destination city matches the request delivery city
2. WHEN displaying matching trips, THE System SHALL show only trips with active status
3. WHEN displaying matching trips, THE System SHALL show only upcoming trips (departure date in the future)
4. WHEN displaying matching trips, THE System SHALL show only trips where available capacity is greater than or equal to the request weight
5. WHEN a requester's request is not active, THE System SHALL prevent viewing matching trips

### Requirement 3: Match Creation Validation

**User Story:** As a user, I want the system to validate compatibility before creating a match, so that invalid matches are prevented.

#### Acceptance Criteria

1. WHEN creating a match, THE System SHALL verify the trip departure date has not passed
2. WHEN creating a match, THE System SHALL verify the request status is active
3. WHEN creating a match, THE System SHALL verify the trip status is active
4. WHEN creating a match, THE System SHALL verify the trip available capacity is sufficient for the request weight
5. WHEN creating a match, THE System SHALL verify the traveler and requester are different users
6. WHEN creating a match, THE System SHALL verify no existing match exists for the trip-request pair
7. IF any validation fails, THEN THE System SHALL display a user-friendly error message

### Requirement 4: Match Creation Transaction

**User Story:** As a system administrator, I want match creation to be atomic and consistent, so that data integrity is maintained.

#### Acceptance Criteria

1. WHEN a match is created, THE System SHALL use a Firestore transaction to ensure atomicity
2. WHEN a match is created, THE System SHALL generate a deterministic match ID using the format tripId__requestId
3. WHEN a match is created, THE System SHALL set the match status to pending
4. WHEN a match is created, THE System SHALL update the request status to matched
5. WHEN a match is created, THE System SHALL store the matched trip ID and traveler ID in the request document
6. WHEN a match is created, THE System SHALL set the participants array to include both traveler and requester IDs
7. WHEN a match is created, THE System SHALL set creation and update timestamps using server time

### Requirement 5: Duplicate Match Prevention

**User Story:** As a user, I want to be prevented from creating duplicate matches, so that the same trip-request pair is not matched multiple times.

#### Acceptance Criteria

1. WHEN a match creation is attempted, THE System SHALL check if a match already exists for the trip-request pair
2. WHEN a duplicate match is detected, THE System SHALL reject the creation with an error message
3. WHEN checking for duplicates, THE System SHALL use the deterministic match ID format
4. THE System SHALL enforce duplicate prevention at both the BLoC layer and repository transaction layer

### Requirement 6: Filtering Query Performance

**User Story:** As a developer, I want matching queries to be efficient, so that the app remains responsive.

#### Acceptance Criteria

1. WHEN querying matching requests, THE System SHALL filter by destination city using Firestore where clause
2. WHEN querying matching requests, THE System SHALL filter by status using Firestore where clause
3. WHEN querying matching trips, THE System SHALL filter by destination city using Firestore where clause
4. WHEN querying matching trips, THE System SHALL filter by status using Firestore where clause
5. WHEN additional filtering is needed, THE System SHALL apply client-side filtering for weight and capacity
6. WHEN additional filtering is needed, THE System SHALL apply client-side filtering for trip dates

### Requirement 7: User Feedback and Error Handling

**User Story:** As a user, I want clear feedback when matches cannot be created, so that I understand what went wrong.

#### Acceptance Criteria

1. WHEN a trip date has passed, THE System SHALL display the message "Trip date already passed"
2. WHEN a request is already matched, THE System SHALL display the message "Request already matched or unavailable"
3. WHEN a trip is not available, THE System SHALL display the message "Trip is not available"
4. WHEN capacity is insufficient, THE System SHALL display the message "Trip capacity is insufficient for this request"
5. WHEN a duplicate match is detected, THE System SHALL display the message "A match already exists for this trip and request"
6. WHEN trip or request is not found, THE System SHALL display the message "Trip not found" or "Request not found"
7. WHEN traveler and requester are the same user, THE System SHALL display the message "Traveler and requester cannot be the same user"
