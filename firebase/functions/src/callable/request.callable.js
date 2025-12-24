/**
 * Request Callable Functions
 */

const functions = require("firebase-functions/v1");
const { db, FieldValue, Timestamp, collections } = require("../config/firebase");
const { validateAuth, handleError, throwError } = require("../utils/errors");
const { ERROR_CODES, REQUEST_STATUS } = require("../utils/constants");
const validationService = require("../services/validation.service");

/**
 * Create a new delivery request
 */
exports.createRequest = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    // Check if user is verified
    const userDoc = await db.collection(collections.USERS).doc(auth.uid).get();
    if (!userDoc.exists || !userDoc.data().isVerified) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "Only verified users can create requests");
    }
    
    // Validate input
    const validation = validationService.validateRequest(data);
    if (!validation.isValid) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, validation.errors.join(", "));
    }
    
    const request = {
      requesterId: auth.uid,
      requesterName: userDoc.data().displayName,
      requesterPhoto: userDoc.data().photoURL || null,
      title: data.title,
      description: data.description,
      category: data.category || "general",
      weight: data.weight,
      pickupCity: data.pickupCity,
      pickupCountry: data.pickupCountry || "Ethiopia",
      pickupAddress: data.pickupAddress || "",
      deliveryCity: data.deliveryCity,
      deliveryCountry: data.deliveryCountry,
      deliveryAddress: data.deliveryAddress || "",
      recipientName: data.recipientName || "",
      recipientPhone: data.recipientPhone || "",
      images: data.images || [],
      offerAmount: data.offerAmount || 0,
      deadline: data.deadline ? Timestamp.fromDate(new Date(data.deadline)) : null,
      status: REQUEST_STATUS.ACTIVE,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };
    
    const requestRef = await db.collection(collections.REQUESTS).add(request);
    
    return { 
      success: true, 
      requestId: requestRef.id,
      message: "Request created successfully" 
    };
  } catch (error) {
    handleError(error, "createRequest");
  }
});

/**
 * Update an existing request
 */
exports.updateRequest = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { requestId, ...updateData } = data;
    
    if (!requestId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Request ID is required");
    }
    
    const requestDoc = await db.collection(collections.REQUESTS).doc(requestId).get();
    
    if (!requestDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Request not found");
    }
    
    if (requestDoc.data().requesterId !== auth.uid) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You can only update your own requests");
    }
    
    if (requestDoc.data().status !== REQUEST_STATUS.ACTIVE) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "Can only update active requests");
    }
    
    const allowedFields = [
      "title", "description", "weight", "offerAmount", 
      "recipientName", "recipientPhone", "images", "deadline"
    ];
    
    const filteredUpdate = {};
    allowedFields.forEach((field) => {
      if (updateData[field] !== undefined) {
        if (field === "deadline") {
          filteredUpdate[field] = Timestamp.fromDate(new Date(updateData[field]));
        } else {
          filteredUpdate[field] = updateData[field];
        }
      }
    });
    
    filteredUpdate.updatedAt = FieldValue.serverTimestamp();
    
    await db.collection(collections.REQUESTS).doc(requestId).update(filteredUpdate);
    
    return { success: true, message: "Request updated successfully" };
  } catch (error) {
    handleError(error, "updateRequest");
  }
});

/**
 * Search for requests
 */
exports.searchRequests = functions.https.onCall(async (data, context) => {
  try {
    validateAuth(context);
    
    const { 
      deliveryCity, 
      deliveryCountry, 
      maxWeight,
      category,
      limit = 20,
      lastRequestId 
    } = data;
    
    let query = db
      .collection(collections.REQUESTS)
      .where("status", "==", REQUEST_STATUS.ACTIVE)
      .orderBy("createdAt", "desc");
    
    if (deliveryCountry) {
      query = query.where("deliveryCountry", "==", deliveryCountry);
    }
    
    if (category) {
      query = query.where("category", "==", category);
    }
    
    // Pagination
    if (lastRequestId) {
      const lastDoc = await db.collection(collections.REQUESTS).doc(lastRequestId).get();
      if (lastDoc.exists) {
        query = query.startAfter(lastDoc);
      }
    }
    
    query = query.limit(limit);
    
    const snapshot = await query.get();
    
    let requests = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    }));
    
    // Client-side filtering
    if (deliveryCity) {
      const normalizedCity = deliveryCity.toLowerCase().trim();
      requests = requests.filter((req) => 
        req.deliveryCity.toLowerCase().includes(normalizedCity)
      );
    }
    
    if (maxWeight) {
      requests = requests.filter((req) => req.weight <= maxWeight);
    }
    
    return { 
      success: true, 
      requests,
      hasMore: snapshot.docs.length === limit
    };
  } catch (error) {
    handleError(error, "searchRequests");
  }
});

/**
 * Cancel a request
 */
exports.cancelRequest = functions.https.onCall(async (data, context) => {
  try {
    const auth = validateAuth(context);
    
    const { requestId, reason } = data;
    
    if (!requestId) {
      throwError(ERROR_CODES.INVALID_ARGUMENT, "Request ID is required");
    }
    
    const requestRef = db.collection(collections.REQUESTS).doc(requestId);
    const requestDoc = await requestRef.get();
    
    if (!requestDoc.exists) {
      throwError(ERROR_CODES.NOT_FOUND, "Request not found");
    }
    
    if (requestDoc.data().requesterId !== auth.uid) {
      throwError(ERROR_CODES.PERMISSION_DENIED, "You can only cancel your own requests");
    }
    
    await requestRef.update({
      status: REQUEST_STATUS.CANCELLED,
      cancelReason: reason || "Cancelled by user",
      cancelledAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    return { success: true, message: "Request cancelled successfully" };
  } catch (error) {
    handleError(error, "cancelRequest");
  }
});