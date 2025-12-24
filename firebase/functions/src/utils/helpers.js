/**
 * Utility Helper Functions
 */

const { Timestamp } = require("../config/firebase");
const { differenceInDays, isBefore } = require("date-fns");

/**
 * Generate a unique ID
 */
const generateId = (prefix = "") => {
  const timestamp = Date.now().toString(36);
  const random = Math.random().toString(36).substring(2, 8);
  return prefix ? `${prefix}_${timestamp}${random}` : `${timestamp}${random}`;
};

/**
 * Check if dates overlap
 */
const datesOverlap = (start1, end1, start2, end2) => {
  const s1 = start1 instanceof Timestamp ? start1.toDate() : new Date(start1);
  const e1 = end1 instanceof Timestamp ? end1.toDate() : new Date(end1);
  const s2 = start2 instanceof Timestamp ? start2.toDate() : new Date(start2);
  const e2 = end2 instanceof Timestamp ? end2.toDate() : new Date(end2);
  
  return s1 <= e2 && s2 <= e1;
};

/**
 * Calculate days until date
 */
const daysUntil = (date) => {
  const targetDate = date instanceof Timestamp ? date.toDate() : new Date(date);
  return differenceInDays(targetDate, new Date());
};

/**
 * Check if date is in the past
 */
const isPastDate = (date) => {
  const targetDate = date instanceof Timestamp ? date.toDate() : new Date(date);
  return isBefore(targetDate, new Date());
};

/**
 * Normalize city name for matching
 */
const normalizeCity = (city) => {
  return city
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9\s]/g, "")
    .replace(/\s+/g, " ");
};

/**
 * Calculate match score between trip and request
 */
const calculateMatchScore = (trip, request) => {
  let score = 0;
  
  // Exact city match
  if (normalizeCity(trip.destinationCity) === normalizeCity(request.deliveryCity)) {
    score += 50;
  }
  
  // Country match
  if (trip.destinationCountry === request.deliveryCountry) {
    score += 20;
  }
  
  // Weight capacity
  if (trip.availableWeight >= request.weight) {
    score += 20;
  }
  
  // Date proximity (trips departing soon score higher)
  const daysToTrip = daysUntil(trip.departureDate);
  if (daysToTrip <= 7) {
    score += 10;
  } else if (daysToTrip <= 14) {
    score += 5;
  }
  
  return score;
};

/**
 * Sanitize user input
 */
const sanitizeInput = (input) => {
  if (typeof input !== "string") return input;
  return input
    .trim()
    .replace(/<[^>]*>/g, "") // Remove HTML tags
    .substring(0, 10000); // Limit length
};

/**
 * Format user for response (remove sensitive data)
 */
const formatUserForResponse = (userData) => {
  const { email, phone, ...safeData } = userData;
  return {
    ...safeData,
    email: email ? maskEmail(email) : null,
    phone: phone ? maskPhone(phone) : null,
  };
};

/**
 * Mask email address
 */
const maskEmail = (email) => {
  const [name, domain] = email.split("@");
  const maskedName = name.charAt(0) + "***" + name.charAt(name.length - 1);
  return `${maskedName}@${domain}`;
};

/**
 * Mask phone number
 */
const maskPhone = (phone) => {
  if (phone.length < 4) return "****";
  return phone.slice(0, 3) + "****" + phone.slice(-2);
};

/**
 * Batch process array with Firestore batch limits
 */
const processBatch = async (items, processor, batchSize = 500) => {
  const results = [];
  for (let i = 0; i < items.length; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    const batchResults = await Promise.all(batch.map(processor));
    results.push(...batchResults);
  }
  return results;
};

module.exports = {
  generateId,
  datesOverlap,
  daysUntil,
  isPastDate,
  normalizeCity,
  calculateMatchScore,
  sanitizeInput,
  formatUserForResponse,
  maskEmail,
  maskPhone,
  processBatch,
};