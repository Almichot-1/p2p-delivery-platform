# Software Requirements Specification (SRS)
# &
# Software Design Architecture (SDA)

**Project:** Diaspora Peer Delivery Mobile Application ("Diaspora Delivery")  
**Version:** 1.0.0  
**Document Type:** Academic Submission  
**Date:** January 2025  

**Document Control**
| Item | Value |
|---|---|
| Owner | Project Team |
| Status | Submission Draft |
| Intended Audience | Stakeholders, Developers, QA, Academic Evaluators |

---

## TABLE OF CONTENTS

### Part I: Software Requirements Specification (SRS)
1. Introduction  
   1.1 Purpose  
   1.2 Scope  
   1.3 Definitions, Acronyms, and Abbreviations  
   1.4 References  
   1.5 Overview  
2. Overall Description  
   2.1 Product Perspective  
   2.2 Product Functions  
   2.3 User Classes and Characteristics  
   2.4 Operating Environment  
   2.5 Design and Implementation Constraints  
   2.6 Assumptions and Dependencies  
3. Specific Requirements  
   3.1 External Interface Requirements  
   3.2 Functional Requirements  
   3.3 Non-Functional Requirements  
   3.4 System Features  
4. Use Cases  
5. Data Requirements  
6. System Models  

### Part II: Software Design Architecture (SDA)
7. Architectural Overview  
   7.1 Architectural Goals  
   7.2 Architectural Style  
   7.3 System Context  
8. System Architecture  
   8.1 High-Level Architecture  
   8.2 Component Architecture  
   8.3 Layer Architecture  
9. Frontend Architecture  
   9.1 Flutter Application Structure  
   9.2 State Management  
   9.3 Navigation Architecture  
   9.4 UI Component Library  
10. Backend Architecture  
   10.1 Firebase Services Architecture  
   10.2 Cloud Functions Design  
   10.3 Database Design  
   10.4 Storage Architecture  
11. Data Architecture  
   11.1 Data Models  
   11.2 Database Schema  
   11.3 Data Flow Diagrams  
12. Security Architecture  
   12.1 Authentication & Authorization  
   12.2 Data Security  
   12.3 Security Rules  
13. Integration Architecture  
   13.1 Third-Party Integrations  
   13.2 API Specifications  
14. Deployment Architecture  
   14.1 Deployment Diagram  
   14.2 CI/CD Pipeline  
   14.3 Environment Configuration  
15. Quality Attributes  
16. Testing Strategy  

---

# PART I: SOFTWARE REQUIREMENTS SPECIFICATION (SRS)

## 1. INTRODUCTION

### 1.1 Purpose
This Software Requirements Specification (SRS) defines the requirements for the **Diaspora Peer Delivery Mobile Application** ("Diaspora Delivery"). The document is intended for:
- **Development team**: implement and validate system capabilities.
- **Project stakeholders**: confirm scope, priorities, and constraints.
- **Quality assurance team**: derive test plans and acceptance criteria.
- **Academic evaluators**: assess completeness, feasibility, and rigor.

This SRS is structured to align with IEEE-style SRS practices (e.g., IEEE 830).

### 1.2 Scope

#### 1.2.1 Product Name
**Diaspora Delivery — Peer-to-Peer Delivery Platform**

#### 1.2.2 Product Description
Diaspora Delivery is a mobile application that connects diaspora community members who want to send items to Ethiopia (**Requesters**) with travelers who are already going to Ethiopia (**Travelers**). The platform supports:
- Posting trips and delivery requests
- Matching requests to suitable trips
- Secure in-app communication
- Verification and trust features (KYC, ratings)
- Status tracking and notifications

Unless otherwise stated, the term **User** refers to either a Requester or a Traveler.

#### 1.2.3 Benefits
| Benefit | Description |
|---|---|
| Cost Savings | Reduces reliance on expensive international shipping |
| Speed | Faster delivery aligned with real trips |
| Trust | Verification + ratings reduce risk |
| Community | Supports diaspora mutual aid and coordination |
| Convenience | Mobile-first workflow for end-to-end coordination |

#### 1.2.4 Objectives
- Provide a secure peer-delivery coordination platform.
- Implement trust mechanisms (verification, reporting, ratings).
- Provide real-time chat and event notifications.
- Support request/trip lifecycle status and auditing.
- Minimize operational burden using a serverless backend.

### 1.3 Definitions, Acronyms, and Abbreviations
| Term | Definition |
|---|---|
| Requester | User who posts a delivery request |
| Traveler | User who posts travel plans and carries items |
| Trip | Travel listing: origin, destination, dates, capacity |
| Request | Delivery request: item, weight, locations, recipient |
| Match | Agreement candidate linking a request and a trip |
| BaaS | Backend-as-a-Service |
| Firebase | Google backend platform (Auth, Firestore, Functions, Storage, FCM) |
| Firestore | Firebase NoSQL document database |
| Cloud Functions | Serverless backend code triggered by events / HTTPS |
| FCM | Firebase Cloud Messaging (push notifications) |
| BLoC | State management pattern for Flutter |
| CRUD | Create, Read, Update, Delete |
| OTP | One-Time Password |
| API | Application Programming Interface |
| SDK | Software Development Kit |
| UI/UX | User Interface / User Experience |
| CI/CD | Continuous Integration / Continuous Deployment |

### 1.4 References
| Reference | Description |
|---|---|
| IEEE 830-1998 | Recommended Practice for SRS |
| IEEE 1016-2009 | Standard for Software Design Descriptions |
| Firebase Docs | https://firebase.google.com/docs |
| Flutter Docs | https://flutter.dev/docs |
| bloc library | https://bloclibrary.dev |
| Material Design 3 | https://m3.material.io |
| WCAG 2.1 | https://www.w3.org/TR/WCAG21/ |

### 1.5 Overview
This document has two parts:
- **Part I (SRS):** What the system must do (requirements).
- **Part II (SDA):** How the system is designed (architecture).

---

## 2. OVERALL DESCRIPTION

### 2.1 Product Perspective
Diaspora Delivery is a **mobile client** (Flutter) backed by **serverless cloud services** (Firebase). No dedicated custom backend server is required.

**System Context (conceptual):**
- Users (Requester/Traveler/Admin) interact with the Flutter app.
- The app communicates with Firebase services:
  - Firebase Auth (identity)
  - Firestore (data + real-time updates)
  - Storage (images and documents)
  - Cloud Functions (business logic)
  - FCM (push notifications)

### 2.2 Product Functions
This section lists the product’s major capabilities at a high level.

| Function ID | Function Name | Description |
|---|---|---|
| F-AUTH | Authentication | Register, login, OTP, password reset, sessions |
| F-PROFILE | Profile Management | Create/edit profile, upload photo, preferences |
| F-VERIFY | Identity Verification | Document upload, verification workflow |
| F-TRIP | Trip Management | Create/browse/edit/cancel/complete trips |
| F-REQUEST | Request Management | Create/browse/edit/cancel delivery requests |
| F-MATCH | Matching System | Suggest and manage matches between trips/requests |
| F-CHAT | Messaging | Real-time chat for matched users |
| F-NOTIFY | Notifications | Push + in-app notifications |
| F-REVIEW | Reviews | Ratings & reviews post-delivery |
| F-SEARCH | Search & Filter | Search trips/requests by route/date/etc. |
| F-ADMIN | Admin Moderation | Review verification, handle reports, manage content |

### 2.3 User Classes and Characteristics
| User Class | Description | Technical Level | Frequency |
|---|---|---|---|
| Guest | Browses public info, limited access | Low | Occasional |
| Requester | Posts requests, communicates, reviews | Low–Medium | Regular |
| Traveler | Posts trips, accepts matches, delivers | Low–Medium | Periodic |
| Dual User | Both requester and traveler | Medium | Frequent |
| Admin | Moderation and verification review | High | Daily |

### 2.4 Operating Environment
**Client**
- Android 8.0+ (API 26), iOS 13.0+
- Flutter 3.16+ / Dart 3.2+

**Backend**
- Firebase: Auth, Firestore, Storage, Cloud Functions, FCM

**Network**
- Minimum: 3G; recommended: 4G/5G/Wi-Fi

**Supported Languages**
- English (EN)
- Amharic (AM)

### 2.5 Design and Implementation Constraints
| Constraint ID | Constraint | Impact |
|---|---|---|
| C-01 | Flutter cross-platform single codebase | Shared UI/logic across iOS/Android |
| C-02 | Firebase backend (no custom server) | Business logic must fit Functions + Firestore |
| C-03 | Firestore query/index limitations | Requires denormalization and planned indexes |
| C-04 | Upload size limit (e.g., 10MB) | Enforce compression and validation |
| C-05 | Real-time listener limits/cost | Optimize subscriptions and pagination |
| C-06 | Multi-language (English + Amharic) | Localization across UI and messaging |
| C-07 | Privacy/compliance constraints | Data minimization + controls (GDPR/CCPA) |

### 2.6 Assumptions and Dependencies
**Assumptions**
- Users have smartphones with internet.
- Travelers have legitimate documents and comply with travel regulations.
- Users provide accurate item information.

**Dependencies**
- Firebase services availability.
- External APIs such as Google Maps (if enabled).
- App store approvals and policy compliance.

---

## 3. SPECIFIC REQUIREMENTS

### 3.1 External Interface Requirements

#### 3.1.1 User Interfaces
- Material Design 3 compliant UI.
- Responsive layout for different screen sizes.
- Accessibility: WCAG 2.1 AA support.
- Localization: English and Amharic.
- Dark/light mode support.

**Screen Hierarchy (logical)**
- Auth flow: Splash, onboarding, login, register, OTP, reset password
- Main app: Home, Trips, Requests, Matches, Chat
- Profile: View/edit, verification, settings
- Notifications: In-app inbox

#### 3.1.2 Hardware Interfaces
- Camera and photo library for document/item images
- GPS (optional) for city suggestions
- Local storage for caching

#### 3.1.3 Software Interfaces
| Interface | Type | Data |
|---|---|---|
| Firebase Auth | SDK | Tokens/JSON |
| Firestore | SDK (real-time) | Documents/Collections |
| Firebase Storage | SDK | Binary objects |
| Cloud Functions | Callable/HTTPS | JSON |
| FCM | SDK | Push payload |
| Maps API (optional) | REST | JSON |

#### 3.1.4 Communication Interfaces
- HTTPS (443) for API calls
- WSS (443) for Firestore real-time streams
- FCM (managed) for push notifications

### 3.2 Functional Requirements

#### 3.2.1 Authentication (FR-AUTH)

**FR-AUTH-001: User Registration (Email/Password)**
- **Priority:** High
- **Description:** The system shall allow a guest user to register using email and password.
- **Inputs:** full name, email, password, optional phone.
- **Main Processing:** validate inputs → create Firebase Auth user → create Firestore user profile document → start user session.
- **Outputs:** authenticated session; user routed to main app.
- **Acceptance Criteria:**
   - Given valid registration data, when the user submits, then the account is created and the user is signed in.
   - Given an email already registered, when the user submits, then an error is displayed and account creation is prevented.

**FR-AUTH-002: User Login (Email/Password)**
- **Priority:** High
- **Description:** The system shall authenticate a registered user using email and password.

**FR-AUTH-003: Phone OTP Login**
- **Priority:** Medium
- **Description:** The system shall authenticate a user using phone number verification (OTP).

**FR-AUTH-004: Social Login (Google)**
- **Priority:** Medium
- **Description:** The system shall support Google Sign-In to create or link a user account.

**FR-AUTH-005: Password Reset**
- **Priority:** Medium
- **Description:** The system shall allow a user to request a password reset via email.

**FR-AUTH-006: Email Verification (Optional)**
- **Priority:** Low
- **Description:** The system shall support email verification to increase account trust.

**FR-AUTH-007: Session Management**
- **Priority:** High
- **Description:** The system shall persist user sessions across app restarts using secure tokens and automatic refresh.

**FR-AUTH-008: Logout**
- **Priority:** High
- **Description:** The system shall allow users to sign out and clear local session state.

#### 3.2.2 User Profile & Identity Verification (FR-PROFILE / FR-VERIFY)

**FR-PROFILE-001: View Profile**
- **Priority:** High
- **Description:** The system shall display user profile information (photo, name, rating summary, verification status).

**FR-PROFILE-002: Edit Profile**
- **Priority:** High
- **Description:** The system shall allow users to edit profile fields: photo, name, phone, languages, and bio.

**FR-PROFILE-003: Online Status**
- **Priority:** Medium
- **Description:** The system shall update and display user online/last-seen status where privacy settings allow.

**FR-VERIFY-001: Submit Verification Documents**
- **Priority:** High
- **Description:** The system shall allow a user to submit identity documents for verification.
- **Main Processing:** select document type → capture/select image → upload to Storage → create verification record → set status to pending.

**FR-VERIFY-002: Verification Status Tracking**
- **Priority:** High
- **Description:** The system shall support verification states: unverified, pending, verified, rejected.

**FR-VERIFY-003: Admin Verification Review**
- **Priority:** High
- **Description:** The system shall allow admins to approve or reject verification submissions.

**FR-VERIFY-004: Verification-Based Feature Gating (Configurable)**
- **Priority:** Medium
- **Description:** The system shall restrict selected actions (e.g., posting trips) to verified users based on configuration.

#### 3.2.3 Trip Management (FR-TRIP)

**FR-TRIP-001: Create Trip**
- **Priority:** High
- **Description:** The system shall allow a traveler to post a trip with route, dates, and capacity.
- **Validation Rules:** departure date must be in the future; return date (if provided) must be after departure; capacity must be within allowed range.

**FR-TRIP-002: Browse Trips**
- **Priority:** High
- **Description:** The system shall allow users to browse trips using list and basic filters (destination city, date range).

**FR-TRIP-003: Trip Details**
- **Priority:** High
- **Description:** The system shall display full trip information and traveler summary.

**FR-TRIP-004: Edit Trip**
- **Priority:** High
- **Description:** The system shall allow the traveler who created a trip to edit the trip before completion.

**FR-TRIP-005: Cancel Trip**
- **Priority:** High
- **Description:** The system shall allow the traveler to cancel a trip and notify impacted matched users.

**FR-TRIP-006: Complete Trip**
- **Priority:** Medium
- **Description:** The system shall allow the traveler to mark a trip as completed.

**FR-TRIP-007: My Trips**
- **Priority:** High
- **Description:** The system shall provide a list of trips created by the signed-in traveler.

#### 3.2.4 Request Management (FR-REQUEST)

**FR-REQUEST-001: Create Request (Multi-step)**
- **Priority:** High
- **Description:** The system shall allow a requester to create a delivery request using a multi-step form.
- **Steps:** item details → locations → recipient → photos & pricing.
- **Validation Rules:** required fields must be present; weight within allowed range; addresses within length limits.

**FR-REQUEST-002: Upload Request Photos (Optional)**
- **Priority:** Medium
- **Description:** The system shall allow uploading up to a configured number of item photos with size/type limits.

**FR-REQUEST-003: Browse Requests**
- **Priority:** High
- **Description:** The system shall allow travelers to browse requests using list and basic filters.

**FR-REQUEST-004: Request Details**
- **Priority:** High
- **Description:** The system shall display full request information and requester summary.

**FR-REQUEST-005: Edit Request**
- **Priority:** High
- **Description:** The system shall allow the requester who created a request to edit it prior to matching/commitment.

**FR-REQUEST-006: Cancel Request**
- **Priority:** High
- **Description:** The system shall allow the requester to cancel a request and notify impacted matched users.

**FR-REQUEST-007: My Requests**
- **Priority:** High
- **Description:** The system shall provide a list of requests created by the signed-in requester.

#### 3.2.5 Matching System (FR-MATCH)

**FR-MATCH-001: Match Suggestion Generation**
- **Priority:** High
- **Description:** The system shall compute match suggestions between new trips and existing requests and vice versa.

**FR-MATCH-002: Match Scoring**
- **Priority:** High
- **Description:** The system shall compute a match score based on configurable criteria (route compatibility, date compatibility, capacity, item type).

**FR-MATCH-003: Match Lifecycle Management**
- **Priority:** High
- **Description:** The system shall manage match statuses.
- **States:** pending, accepted, rejected, confirmed, picked_up, in_transit, delivered, completed, cancelled, expired.

**FR-MATCH-004: Accept/Reject Match**
- **Priority:** High
- **Description:** The system shall allow the traveler to accept or reject a pending match.

**FR-MATCH-005: Confirm Match**
- **Priority:** High
- **Description:** The system shall allow both parties to confirm an accepted match prior to pickup.

**FR-MATCH-006: Delivery Status Updates**
- **Priority:** High
- **Description:** The system shall support status updates through pickup/in-transit/delivered/completed.

**FR-MATCH-007: Match Cancellation**
- **Priority:** High
- **Description:** The system shall allow either party to cancel a match based on allowed rules and notify the counterpart.

#### 3.2.6 Communication (FR-CHAT)

**FR-CHAT-001: Real-time Text Messaging**
- **Priority:** High
- **Description:** The system shall enable participants of a match to exchange real-time text messages.

**FR-CHAT-002: Image Messaging**
- **Priority:** Medium
- **Description:** The system shall allow participants to send images in chat with upload limits.

**FR-CHAT-003: Conversation List**
- **Priority:** High
- **Description:** The system shall provide a list of conversations (one per match) including last message and unread indicator.

**FR-CHAT-004: Read Receipts (Optional)**
- **Priority:** Low
- **Description:** The system shall support read status for messages.

#### 3.2.7 Notifications (FR-NOTIFY)

**FR-NOTIFY-001: Push Notifications**
- **Priority:** High
- **Description:** The system shall deliver push notifications for key events (new match, acceptance/confirmation, status updates, new message, review).

**FR-NOTIFY-002: In-App Notification Inbox**
- **Priority:** Medium
- **Description:** The system shall store notifications for later viewing and support mark-as-read.

**FR-NOTIFY-003: Notification Deep Links**
- **Priority:** Medium
- **Description:** The system shall open the relevant screen (match/chat/review) when a notification is tapped.

#### 3.2.8 Reviews & Ratings (FR-REVIEW)

**FR-REVIEW-001: Submit Review**
- **Priority:** Medium
- **Description:** The system shall allow users to rate and review the other party after a match is completed.

**FR-REVIEW-002: Enforce Review Eligibility**
- **Priority:** Medium
- **Description:** The system shall enforce that reviews can only be created for completed matches.

**FR-REVIEW-003: Aggregate Rating Updates**
- **Priority:** Medium
- **Description:** The system shall update and display aggregate ratings based on submitted reviews.

#### 3.2.9 Administration & Moderation (FR-ADMIN)

**FR-ADMIN-001: Admin Authentication and Role**
- **Priority:** High
- **Description:** The system shall restrict admin capabilities to accounts with an admin role.

**FR-ADMIN-002: Review Verification Submissions**
- **Priority:** High
- **Description:** The system shall provide admins with a way to approve/reject verification submissions.

**FR-ADMIN-003: Content Moderation Actions (Minimal)**
- **Priority:** Medium
- **Description:** The system shall allow admins to disable abusive users or remove prohibited content as needed.

### 3.3 Non-Functional Requirements

#### 3.3.1 Performance
| ID | Requirement | Target |
|---|---|---|
| NFR-PERF-001 | Cold start to first usable screen | < 3s |
| NFR-PERF-002 | Navigation transition | < 300ms |
| NFR-PERF-003 | List initial render | < 1s |
| NFR-PERF-004 | Chat delivery latency | < 1s |
| NFR-PERF-005 | Image upload (≤5MB) | < 5s on 1 Mbps |

#### 3.3.2 Reliability
| ID | Requirement | Target |
|---|---|---|
| NFR-REL-001 | Backend uptime | 99.9% |
| NFR-REL-002 | Crash-free users | > 99.5% |
| NFR-REL-003 | Offline read support | Core browsing available |

#### 3.3.3 Security
| ID | Requirement | Implementation |
|---|---|---|
| NFR-SEC-001 | Authentication | Firebase Auth |
| NFR-SEC-002 | Encryption in transit | TLS 1.2+ (target TLS 1.3) |
| NFR-SEC-003 | Authorization | Firestore security rules |
| NFR-SEC-004 | Input validation | Client + Functions validation |
| NFR-SEC-005 | Least privilege access | Per-user/per-match access controls |

#### 3.3.4 Usability & Accessibility
- WCAG 2.1 AA goal; touch targets ≥ 48dp.
- Bilingual UI (English, Amharic).

#### 3.3.5 Maintainability & Scalability
- Feature-based modular code.
- Horizontal scaling via Firebase.

### 3.4 System Features
A prioritized feature list:
- Required: Auth, Profile, Verification, Trips, Requests, Matching, Chat, Notifications, Reviews, Search.
- Desired: Offline improvements, dark mode enhancements, analytics.

---

## 4. USE CASES

### UC-01: User Registration
- **Actor:** Guest
- **Preconditions:** App installed, internet.
- **Postconditions:** User created and logged in.
- **Main Flow:** Open app → register → validate → create Auth user → create profile → home.
- **Alternates:** Social login; email exists.

### UC-02: Create Delivery Request
- **Actor:** Requester
- **Main Flow:** Create request (wizard) → upload photos → submit → create doc → trigger matching.

### UC-03: Post Travel Trip
- **Actor:** Traveler
- **Main Flow:** Create trip → validate → create doc → trigger matching.

### UC-04: Accept Delivery Match
- **Actor:** Traveler
- **Main Flow:** Open match → accept → update status → notify requester → enable chat.

### UC-05: Real-time Chat
- **Actor:** Matched user
- **Main Flow:** Open chat → load messages → send → store message → notify other.

### UC-06: Complete Delivery and Review
- **Actors:** Both
- **Main Flow:** Mark delivered → confirm receipt → complete match → both review.

---

## 5. DATA REQUIREMENTS

### 5.1 Logical Data Model (Summary)
Entities: User, Trip, Request, Match, Message, Review, Notification.
Relationships:
- User creates Trips and Requests
- Trip and Request form Matches
- Match contains Messages
- Users create Reviews for completed Matches

### 5.2 Data Dictionary (Minimal)
**users**
- uid (string, PK)
- fullName (string)
- email (string)
- phone (string?)
- role (enum: requester/traveler/both)
- verificationStatus (enum)
- rating (number)
- createdAt (timestamp)

**trips**
- tripId (string, PK)
- travelerId (string, FK users)
- originCity, destinationCity (string)
- departureDate (timestamp)
- capacityKg (number)
- status (enum)

**requests**
- requestId (string, PK)
- requesterId (string, FK users)
- title, description, category (string)
- weightKg (number)
- pickupCity, deliveryCity (string)
- recipientName, recipientPhone (string)
- status (enum)

**matches**
- matchId (string, PK)
- tripId, requestId (string)
- travelerId, requesterId (string)
- status (enum)

**matches/{matchId}/messages**
- messageId (string)
- senderId (string)
- type (enum: text/image/system)
- content (string)
- createdAt (timestamp)

---

## 6. SYSTEM MODELS

### 6.1 Activity Model (Narrative)
**Delivery Request End-to-End Activity**
1. Requester creates a request (wizard).
2. System validates and stores request + optional images.
3. System generates match suggestions.
4. Traveler reviews suggested matches.
5. Traveler accepts or rejects.
6. If accepted, requester confirms (and traveler confirms if required).
7. Chat is used for coordination.
8. Traveler marks pickup and in-transit milestones.
9. Traveler marks delivered; requester confirms receipt.
10. Match becomes completed; both parties submit reviews.

### 6.2 Sequence Model (Narrative)
**Match Creation (Event-Driven)**
1. Client writes `requests/{requestId}`.
2. Firestore trigger executes a Cloud Function.
3. Cloud Function queries `trips` for compatible route/date/capacity.
4. Cloud Function creates `matches/{matchId}` records.
5. Cloud Function creates `notifications/{notificationId}` records.
6. Cloud Function sends FCM push to relevant users.
7. Client receives real-time updates via Firestore listeners.

### 6.3 State Model (Match)
**Match Status State Machine**
- `pending` → `accepted` | `rejected` | `expired`
- `accepted` → `confirmed` | `cancelled`
- `confirmed` → `picked_up` → `in_transit` → `delivered` → `completed`
- `picked_up`/`in_transit`/`delivered` → `cancelled` (if allowed by policy)

---

# PART II: SOFTWARE DESIGN ARCHITECTURE (SDA)

## 7. ARCHITECTURAL OVERVIEW

### 7.1 Architectural Goals
| Goal | Description |
|---|---|
| Scalability | Support growth without re-architecture |
| Maintainability | Feature modularity and clean boundaries |
| Performance | Smooth UI and fast data access |
| Reliability | Robust state handling and minimal downtime |
| Security | Least privilege access and secure storage |
| Testability | Enable unit/widget/integration testing |
| Cost | Optimize Firebase usage to control spend |

### 7.2 Architectural Style
**Client + Serverless BaaS**
- Flutter as client
- Firebase as backend services
- Event-driven Functions for automation and enforcement

### 7.3 System Context
- Client interacts with Auth/Firestore/Storage/Functions/FCM.
- Optional: Maps/Geocoding integration.

---

## 8. SYSTEM ARCHITECTURE

### 8.1 High-Level Architecture
- Flutter App (Presentation + State + Domain + Data)
- Firebase Backend (Auth, Firestore, Storage, Functions, Messaging)

### 8.2 Component Architecture
**Client Components**
- Auth, Profile/Verification, Trips, Requests, Matching, Chat, Notifications, Reviews

**Backend Components**
- Firestore collections + indexes
- Cloud Functions: matching, notifications, status transition enforcement

### 8.3 Layer Architecture
- Presentation (UI)
- State (BLoC/Cubit)
- Domain (use cases, entities)
- Data (repositories, DTOs)
- Platform (Firebase SDK + device services)

---

## 9. FRONTEND ARCHITECTURE

### 9.1 Flutter Application Structure
- **Architecture pattern:** Feature-first (vertical slices) with shared `core` and `config` modules.
- **Recommended module breakdown:**
   - `core/`: constants, errors, services (logging, connectivity), theme, shared widgets
   - `config/`: dependency injection, routes, environment configuration
   - `features/`: auth, profile, trips, requests, matches, chat, notifications, reviews
- **Coding conventions:**
   - Each feature contains: presentation (screens/widgets), state (bloc/cubit), domain (use cases/entities), data (repositories/dtos).

### 9.2 State Management
- **Approach:** BLoC/Cubit per feature with repository abstraction.
- **State rules:**
   - UI listens only to state; business logic remains inside BLoCs and domain use cases.
   - Real-time Firestore listeners are created in repositories and exposed as streams.
   - Pagination uses query cursors (`startAfter`) and avoids unbounded listeners.
- **Error handling:**
   - Map platform/Firebase exceptions into domain errors.
   - UI displays recoverable errors and retry actions.

### 9.3 Navigation Architecture
- Router-based navigation with:
   - Auth guard (redirect to login if not authenticated)
   - Verification guard (restrict configured flows to verified users)
   - Deep links from notifications (match/chat/review details)
- Primary structure: bottom navigation for main modules (Home, Trips, Requests, Matches, Chat) + stack routes for details and forms.

### 9.4 UI Component Library
- Material Design 3 components with reusable building blocks:
   - Cards: TripCard, RequestCard, MatchCard, ConversationTile
   - Forms: validated text fields, dropdown selectors, date pickers, steppers
   - States: empty, loading, error (with retry)
   - Badges: verification status, match status, urgency

---

## 10. BACKEND ARCHITECTURE

### 10.1 Firebase Services Architecture
- Auth: identity and sessions
- Firestore: primary data store
- Storage: files (docs/photos)
- Functions: automation and business rules
- FCM: push notifications

### 10.2 Cloud Functions Design (Conceptual)
- **Function groupings:**
   - **Matching automation**
      - `onCreateRequest`: evaluate candidate trips, compute score, create match documents, notify travelers.
      - `onCreateTrip`: evaluate candidate requests, compute score, create match documents, notify requesters.
   - **Lifecycle enforcement**
      - `onUpdateMatch`: validate allowed status transitions, write audit timestamps, notify participants.
   - **Messaging notifications**
      - `onCreateMessage`: create notification record and send FCM push to the other participant.
   - **Scheduled maintenance**
      - `expireMatches`: mark pending/accepted matches as expired after a policy threshold (e.g., trip date passed).

- **Idempotency requirement:** Functions shall be designed so repeated triggers do not duplicate matches/notifications.

### 10.3 Database Design
- **Denormalization strategy:** Cache display fields (names, photos, ratings) in `trips`, `requests`, and `matches` to avoid repeated joins.
- **Index strategy (examples):**
   - Trips browse: `(destinationCity, departureDate)`
   - Requests browse: `(deliveryCity, createdAt)`
   - My Trips: `(travelerId, createdAt)`
   - My Requests: `(requesterId, createdAt)`
   - Matches by user: `(participants, updatedAt)` using array-contains + ordering patterns
- **Pagination:** Use `limit` + cursor-based pagination; avoid loading entire collections.

### 10.4 Storage Architecture
- **Path conventions (recommended):**
   - Profile images: `users/{uid}/profile/{fileName}`
   - Verification docs: `users/{uid}/verification/{submissionId}/{fileName}`
   - Request item photos: `requests/{requestId}/images/{fileName}`
   - Chat images: `matches/{matchId}/messages/{messageId}/{fileName}`
- **Controls:** enforce max size, allowed content types, and ownership-based access.

---

## 11. DATA ARCHITECTURE

### 11.1 Data Models
- Entities: User, Trip, Request, Match, Message, Review, Notification.

### 11.2 Database Schema
- Collections: users, trips, requests, matches, reviews, notifications.
- Subcollections: matches/{matchId}/messages.

### 11.3 Data Flow Diagrams (Narrative)
- **DFD-01: Create Request**
   - User submits request form → optional image upload → request document created → function creates match suggestions → notification records created → FCM push.

- **DFD-02: Messaging**
   - User sends message → message document created under match → function sends push to other user → UI updates via real-time stream.

- **DFD-03: Status Update**
   - User changes match status → function validates transition → writes timestamp/audit → notifies participant(s) → UI updates.

---

## 12. SECURITY ARCHITECTURE

### 12.1 Authentication & Authorization
- Firebase Auth for user identity.
- Role-based access for admin via custom claims.

### 12.2 Data Security
- Encrypt in transit (TLS) and at rest (Firebase-managed).
- Store minimal PII; restrict reads by participant.

### 12.3 Security Rules (Principles)
- **Users**
   - Users can read their own full profile.
   - Publicly readable profile fields (if enabled) are limited to non-sensitive fields.
   - Users cannot write verification status fields directly.

- **Trips/Requests**
   - Creator can create and edit their own records (subject to status constraints).
   - Match-linked fields are written only by trusted server logic (Cloud Functions).

- **Matches/Messages**
   - Only match participants can read the match and its messages.
   - Only participants can create messages; message size/type validation applies.

- **Admin**
   - Admin-only write permissions for verification approval and moderation actions.

---

## 13. INTEGRATION ARCHITECTURE

### 13.1 Third-Party Integrations
- Google Sign-In (optional)
- Google Maps/Geocoding (optional)

### 13.2 API Specifications
- Callable Functions for operations requiring server enforcement.
- Firestore as primary API (SDK).

---

## 14. DEPLOYMENT ARCHITECTURE

### 14.1 Deployment Diagram (Narrative)
- Flutter app deployed to iOS/Android stores.
- Firebase project hosts backend services.

### 14.2 CI/CD Pipeline
- Flutter: analyze → test → build.
- Functions: lint/test → deploy.

### 14.3 Environment Configuration
- Separate Firebase projects for dev/stage/prod.
- Use build flavors and environment variables.

---

## 15. QUALITY ATTRIBUTES
- Performance via caching, pagination, and denormalized reads.
- Reliability via retries and idempotent Functions.
- Security via strict rules and participant-only access.
- Maintainability via modular features and DI.

---

## 16. TESTING STRATEGY
- Unit tests: validation, scoring, state transitions.
- Widget tests: forms, lists, chat UI.
- Integration tests: end-to-end flows using staging Firebase.
- Security rule tests: Firebase emulator suite.

---

## Notes for Implementation Alignment
- This document specifies requirements and architecture; branding and visual design specifics are intentionally out of scope.
- Items marked **optional** or **configurable** may be deferred or toggled based on project constraints.

---

**End of Document**
