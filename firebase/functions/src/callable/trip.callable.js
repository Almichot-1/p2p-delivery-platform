/**
 * Trip Callable Functions
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, Timestamp, collections } = require("../config/firebase");
const { validateAuth, handleError, throwError } = require("../utils/errors");
const { ERROR_CODES, TRIP_STATUS } = require("../utils/constants");
const validationService = require("../services/validation.service");

/**
 * Create a new trip
 */
exports.createTrip = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    // Check if user is verified
    const userDoc = await db.collection(collections.USERS).doc(auth.uid).get();
    if (!userDoc.exists || !userDoc.data().isVerified) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "Only verified users can create trips");
    }
    
    // Validate input
    const validation = validationService.validateTrip(data);
    if (!validation.isValid) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, validation.errors.join(", "));
    }
    
    const trip = {
      travelerId: auth.uid,
      travelerName: userDoc.data().displayName,
      travelerPhoto: userDoc.data().photoURL || null,
      originCity: data.originCity,
      originCountry: data.originCountry,
      destinationCity: data.destinationCity,
      destinationCountry: data.destinationCountry,
      departureDate: Timestamp.fromDate(new Date(data.departureDate)),
      arrivalDate: data.arrivalDate ? Timestamp.fromDate(new Date(data.arrivalDate)) : null,
      availableWeight: data.availableWeight,
      pricePerKg: data.pricePerKg || 0,
      notes: data.notes || "",
      status: TRIP_STATUS.ACTIVE,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    
    const tripRef = await db.collection(collections.TRIPS).add(trip);
    
    return { 
      success: true, 
      tripId: tripRef.id,
      message: "Trip created successfully" 
    };
  } catch (error) {
    handleError(error, "createTrip");
  }
});

/**
 * Update an existing trip
 */
exports.updateTrip = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { tripId, ...updateData } = data;
    
    if (!tripId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Trip ID is required");
    }
    
    // Get trip and verify ownership
    const tripDoc = await db.collection(collections.TRIPS).doc(tripId).get();
    
    if (!tripDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Trip not found");
    }
    
    if (tripDoc.data().travelerId !== auth.uid) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You can only update your own trips");
    }
    
    // Filter allowed update fields
    const allowedFields = ["availableWeight", "pricePerKg", "notes", "departureDate", "arrivalDate"];
    const filteredUpdate = {};
    
    allowedFields.forEach((field) => {
      if (updateData[field] !== undefined) {
        if (field === "departureDate" || field === "arrivalDate") {
          filteredUpdate[field] = Timestamp.fromDate(new Date(updateData[field]));
        } else {
          filteredUpdate[field] = updateData[field];
        }
      }
    });
    
    filteredUpdate.updatedAt = FieldValue.serverTimestamp();
    
    await db.collection(collections.TRIPS).doc(tripId).update(filteredUpdate);
    
    return { success: true, message: "Trip updated successfully" };
  } catch (error) {
    handleError(error, "updateTrip");
  }
});

/**
 * Search for trips
 */
exports.searchTrips = functions.https.onCall(async (data, context) => {
  try {
    validateAuth(context);
    
    const { 
      destinationCity, 
      destinationCountry, 
      departureAfter, 
      departureBefore,
      minWeight,
      limit = 20,
      lastTripId 
    } = data;
    
    let query = db
      .collection(collections.TRIPS)
      .where("status", "==", TRIP_STATUS.ACTIVE)
      .orderBy("departureDate", "asc");
    
    if (destinationCountry) {
      query = query.where("destinationCountry", "==", destinationCountry);
    }
    
    if (departureAfter) {
      query = query.where("departureDate", ">=", Timestamp.fromDate(new Date(departureAfter)));
    }
    
    if (departureBefore) {
      query = query.where("departureDate", "<=", Timestamp.fromDate(new Date(departureBefore)));
    }
    
    // Pagination
    if (lastTripId) {
      const lastDoc = await db.collection(collections.TRIPS).doc(lastTripId).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }
    
    query = query.limit(limit);
    
    const snapshot = await query.get();
    
    let trips = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    // Client-side filtering for fields not supported in compound query
    if (destinationCity) {
      const normalizedCity = destinationCity.toLowerCase().trim();
      trips = trips.filter((trip) => 
        trip.destinationCity.toLowerCase().includes(normalizedCity)
      );
    }
    
    if (minWeight) {
      trips = trips.filter((trip) => trip.availableWeight >= minWeight);
    }
    
    return { 
      success: true, 
      trips,
      hasMore: snapshot.docs.length === limit
    };
  } catch (error) {
    handleError(error, "searchTrips");
  }
});

/**
 * Cancel a trip
 */
exports.cancelTrip = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { tripId, reason } = data;
    
    if (!tripId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Trip ID is required");
    }
    
    const tripRef = db.collection(collections.TRIPS).doc(tripId);
    const tripDoc = await tripRef.get();
    
    if (!tripDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Trip not found");
    }
    
    if (tripDoc.data().travelerId !== auth.uid) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You can only cancel your own trips");
    }
    
    await tripRef.update({
      status: TRIP_STATUS.CANCELLED,
      cancelReason: reason || "Cancelled by user",
      cancelledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    return { success: true, message: "Trip cancelled successfully" };
  } catch (error) {
    handleError(error, "cancelTrip");
  }
});