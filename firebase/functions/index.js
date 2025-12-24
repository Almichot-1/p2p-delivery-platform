/**
 * Diaspora Peer Delivery - Cloud Functions Entry Point
 * 
 * This file exports all Cloud Functions for the application.
 */

const admin = require("firebase-admin");
admin.initializeApp();

// ============================================
// AUTH TRIGGERS
// ============================================
const authTriggers = require("./src/triggers/auth.triggers");
exports.onUserCreated = authTriggers.onUserCreated;
exports.onUserDeleted = authTriggers.onUserDeleted;

// ============================================
// TRIP TRIGGERS
// ============================================
const tripTriggers = require("./src/triggers/trip.triggers");
exports.onTripCreated = tripTriggers.onTripCreated;
exports.onTripUpdated = tripTriggers.onTripUpdated;

// ============================================
// REQUEST TRIGGERS
// ============================================
const requestTriggers = require("./src/triggers/request.triggers");
exports.onRequestCreated = requestTriggers.onRequestCreated;
exports.onRequestUpdated = requestTriggers.onRequestUpdated;

// ============================================
// MATCH TRIGGERS
// ============================================
const matchTriggers = require("./src/triggers/match.triggers");
exports.onMatchCreated = matchTriggers.onMatchCreated;
exports.onMatchUpdated = matchTriggers.onMatchUpdated;

// ============================================
// MESSAGE TRIGGERS
// ============================================
const messageTriggers = require("./src/triggers/message.triggers");
exports.onMessageCreated = messageTriggers.onMessageCreated;

// ============================================
// REVIEW TRIGGERS
// ============================================
const reviewTriggers = require("./src/triggers/review.triggers");
exports.onReviewCreated = reviewTriggers.onReviewCreated;

// ============================================
// CALLABLE FUNCTIONS
// ============================================
const userCallable = require("./src/callable/user.callable");
exports.updateUserProfile = userCallable.updateUserProfile;
exports.submitVerification = userCallable.submitVerification;
exports.registerFCMToken = userCallable.registerFCMToken;

const tripCallable = require("./src/callable/trip.callable");
exports.createTrip = tripCallable.createTrip;
exports.updateTrip = tripCallable.updateTrip;
exports.searchTrips = tripCallable.searchTrips;
exports.cancelTrip = tripCallable.cancelTrip;

const requestCallable = require("./src/callable/request.callable");
exports.createRequest = requestCallable.createRequest;
exports.updateRequest = requestCallable.updateRequest;
exports.searchRequests = requestCallable.searchRequests;
exports.cancelRequest = requestCallable.cancelRequest;

const matchCallable = require("./src/callable/match.callable");
exports.respondToMatch = matchCallable.respondToMatch;
exports.completeDelivery = matchCallable.completeDelivery;
exports.getMyMatches = matchCallable.getMyMatches;

const chatCallable = require("./src/callable/chat.callable");
exports.sendMessage = chatCallable.sendMessage;
exports.getMessages = chatCallable.getMessages;
exports.markMessagesRead = chatCallable.markMessagesRead;

const adminCallable = require("./src/callable/admin.callable");
exports.verifyUser = adminCallable.verifyUser;
exports.suspendUser = adminCallable.suspendUser;
exports.resolveReport = adminCallable.resolveReport;
exports.getAdminStats = adminCallable.getAdminStats;

// ============================================
// SCHEDULED FUNCTIONS
// ============================================
const scheduledFunctions = require("./src/scheduled/cleanup.scheduled");
exports.cleanupExpiredTrips = scheduledFunctions.cleanupExpiredTrips;
exports.sendReminders = scheduledFunctions.sendReminders;
exports.generateDailyStats = scheduledFunctions.generateDailyStats;