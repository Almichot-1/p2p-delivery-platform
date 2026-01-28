/**
 * Application Constants
 */

const TRIP_STATUS = {
  ACTIVE: "active",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
  EXPIRED: "expired",
};

const REQUEST_STATUS = {
  ACTIVE: "active",
  MATCHED: "matched",
  IN_TRANSIT: "in_transit",
  DELIVERED: "delivered",
  CANCELLED: "cancelled",
  EXPIRED: "expired",
};

const MATCH_STATUS = {
  PENDING: "pending",
  ACCEPTED: "accepted",
  CONFIRMED: "confirmed",
  PICKED_UP: "picked_up",
  IN_TRANSIT: "in_transit",
  DELIVERED: "delivered",
  REJECTED: "rejected",
  EXPIRED: "expired",
  COMPLETED: "completed",
  CANCELLED: "cancelled",
};

const USER_ROLE = {
  USER: "user",
  ADMIN: "admin",
};

const NOTIFICATION_TYPE = {
  NEW_MATCH: "new_match",
  MATCH_ACCEPTED: "match_accepted",
  MATCH_REJECTED: "match_rejected",
  NEW_MESSAGE: "new_message",
  DELIVERY_COMPLETED: "delivery_completed",
  REVIEW_RECEIVED: "review_received",
  VERIFICATION_APPROVED: "verification_approved",
  VERIFICATION_REJECTED: "verification_rejected",
  TRIP_REMINDER: "trip_reminder",
};

const LIMITS = {
  MAX_WEIGHT_KG: 50,
  MAX_ITEM_WEIGHT_KG: 30,
  MAX_DESCRIPTION_LENGTH: 2000,
  MAX_TITLE_LENGTH: 200,
  MAX_MESSAGE_LENGTH: 5000,
  MAX_IMAGES_PER_REQUEST: 5,
  MATCH_EXPIRY_HOURS: 48,
  TRIP_SEARCH_RADIUS_KM: 50,
};

const ERROR_CODES = {
  UNAUTHENTICATED: "unauthenticated",
  PERMISSION_DENIED: "permission-denied",
  NOT_FOUND: "not-found",
  ALREADY_EXISTS: "already-exists",
  INVALID_ARGUMENT: "invalid-argument",
  RESOURCE_EXHAUSTED: "resource-exhausted",
  INTERNAL: "internal",
};

module.exports = {
  TRIP_STATUS,
  REQUEST_STATUS,
  MATCH_STATUS,
  USER_ROLE,
  NOTIFICATION_TYPE,
  LIMITS,
  ERROR_CODES,
};