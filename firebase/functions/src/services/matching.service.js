/**
 * Matching Service
 * Handles matching logic between trips and requests
 */

const { db, FieldValue, collections } = require("../config/firebase");
const { TRIP_STATUS, REQUEST_STATUS, MATCH_STATUS } = require("../utils/constants");
const { normalizeCity, calculateMatchScore } = require("../utils/helpers");
const notificationService = require("./notification.service");

class MatchingService {
  /**
   * Find matching trips for a request
   */
  async findMatchingTrips(request) {
    try {
      const matchingTrips = [];
      
      // Query active trips to the same destination
      const tripsSnapshot = await db
        .collection(collections.TRIPS)
        .where("status", "==", TRIP_STATUS.ACTIVE)
        .where("destinationCountry", "==", request.deliveryCountry)
        .get();
      
      for (const tripDoc of tripsSnapshot.docs) {
        const trip = { id: tripDoc.id, ...tripDoc.data() };
        
        // Skip if same user
        if (trip.travelerId === request.requesterId) continue;
        
        // Check city match
        const tripCity = normalizeCity(trip.destinationCity);
        const requestCity = normalizeCity(request.deliveryCity);
        
        if (tripCity !== requestCity) continue;
        
        // Check weight capacity
        const tripCapacity = Number(trip.availableCapacityKg ?? trip.availableWeight ?? 0);
        const requestWeight = Number(request.weightKg ?? request.weight ?? 0);
        if (tripCapacity < requestWeight) continue;
        
        // Check date validity (trip should be in future)
        if (trip.departureDate.toDate() < new Date()) continue;
        
        // Calculate match score
        const score = calculateMatchScore(trip, request);
        
        if (score >= 50) {
          matchingTrips.push({ trip, score });
        }
      }
      
      // Sort by score
      matchingTrips.sort((a, b) => b.score - a.score);
      
      return matchingTrips;
    } catch (error) {
      console.error("Error finding matching trips:", error);
      throw error;
    }
  }
  
  /**
   * Find matching requests for a trip
   */
  async findMatchingRequests(trip) {
    try {
      const matchingRequests = [];
      
      // Query active requests to the same destination
      const requestsSnapshot = await db
        .collection(collections.REQUESTS)
        .where("status", "==", REQUEST_STATUS.ACTIVE)
        .where("deliveryCountry", "==", trip.destinationCountry)
        .get();
      
      for (const requestDoc of requestsSnapshot.docs) {
        const request = { id: requestDoc.id, ...requestDoc.data() };
        
        // Skip if same user
        if (request.requesterId === trip.travelerId) continue;
        
        // Check city match
        const tripCity = normalizeCity(trip.destinationCity);
        const requestCity = normalizeCity(request.deliveryCity);
        
        if (tripCity !== requestCity) continue;
        
        // Check weight capacity
        const tripCapacity = Number(trip.availableCapacityKg ?? trip.availableWeight ?? 0);
        const requestWeight = Number(request.weightKg ?? request.weight ?? 0);
        if (tripCapacity < requestWeight) continue;
        
        // Calculate match score
        const score = calculateMatchScore(trip, request);
        
        if (score >= 50) {
          matchingRequests.push({ request, score });
        }
      }
      
      // Sort by score
      matchingRequests.sort((a, b) => b.score - a.score);
      
      return matchingRequests;
    } catch (error) {
      console.error("Error finding matching requests:", error);
      throw error;
    }
  }
  
  /**
   * Create a match between trip and request
   */
  async createMatch(trip, request) {
    try {
      // Check if match already exists
      const existingMatch = await db
        .collection(collections.MATCHES)
        .where("tripId", "==", trip.id)
        .where("requestId", "==", request.id)
        .get();
      
      if (!existingMatch.empty) {
        console.log("Match already exists");
        return null;
      }

      // Prefer denormalized display fields from trip/request docs (written by the client)
      const travelerName = trip.travelerName || "";
      const travelerPhoto = trip.travelerPhoto || null;
      const travelerRating = Number(trip.travelerRating ?? 0);
      const requesterName = request.requesterName || "";
      const requesterPhoto = request.requesterPhoto || null;
      const requesterRating = Number(request.requesterRating ?? 0);

      const tripDate = trip.departureDate; // Firestore Timestamp
      const itemTitle = request.title || "";
      const route = `${trip.originCity || ""} → ${trip.destinationCity || ""}`.trim();
      const agreedPrice = Number(request.offeredPrice ?? 0);
      
      // Create match document
      const match = {
        tripId: trip.id,
        requestId: request.id,
        travelerId: trip.travelerId,
        requesterId: request.requesterId,
        participants: [trip.travelerId, request.requesterId],
        status: MATCH_STATUS.PENDING,
        travelerName,
        travelerPhoto,
        travelerRating,
        requesterName,
        requesterPhoto,
        requesterRating,
        itemTitle,
        route,
        tripDate,
        agreedPrice,
        lastMessage: null,
        lastMessageAt: null,
        lastMessageSenderId: null,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      
      const matchRef = await db.collection(collections.MATCHES).add(match);
      
      // Send notifications
      await notificationService.sendMatchNotification(
        { id: matchRef.id, ...match },
        trip,
        request
      );
      
      return matchRef.id;
    } catch (error) {
      console.error("Error creating match:", error);
      throw error;
    }
  }
  
  /**
   * Process matches for a new request
   */
  async processNewRequest(requestId, request) {
    try {
      const matchingTrips = await this.findMatchingTrips(request);
      
      console.log(`Found ${matchingTrips.length} matching trips for request ${requestId}`);
      
      // Create matches for top 5 results
      const topMatches = matchingTrips.slice(0, 5);
      
      for (const { trip } of topMatches) {
        await this.createMatch(trip, { id: requestId, ...request });
      }
      
      return topMatches.length;
    } catch (error) {
      console.error("Error processing new request:", error);
      throw error;
    }
  }
  
  /**
   * Process matches for a new trip
   */
  async processNewTrip(tripId, trip) {
    try {
      const matchingRequests = await this.findMatchingRequests(trip);
      
      console.log(`Found ${matchingRequests.length} matching requests for trip ${tripId}`);
      
      // Create matches for top 5 results
      const topMatches = matchingRequests.slice(0, 5);
      
      for (const { request } of topMatches) {
        await this.createMatch({ id: tripId, ...trip }, request);
      }
      
      return topMatches.length;
    } catch (error) {
      console.error("Error processing new trip:", error);
      throw error;
    }
  }
  
  /**
   * Accept a match
   */
  async acceptMatch(matchId, userId) {
    const matchRef = db.collection(collections.MATCHES).doc(matchId);
    const matchDoc = await matchRef.get();
    
    if (!matchDoc.exists) {
      throw new Error("Match not found");
    }
    
    const match = matchDoc.data();
    
    if (!match.participants.includes(userId)) {
      throw new Error("User not a participant in this match");
    }
    
    if (match.status !== MATCH_STATUS.PENDING) {
      throw new Error("Match is not in pending status");
    }
    
    // Update match status
    await matchRef.update({
      status: MATCH_STATUS.ACCEPTED,
      acceptedBy: userId,
      acceptedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    // Update request status
    await db.collection(collections.REQUESTS).doc(match.requestId).update({
      status: REQUEST_STATUS.MATCHED,
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    // Get user info for notification
    const userDoc = await db.collection(collections.USERS).doc(userId).get();
    const userName = userDoc.data().displayName;
    
    // Notify other participant
    const otherUserId = match.participants.find((p) => p !== userId);
    await notificationService.sendMatchAcceptedNotification(
      { id: matchId, ...match },
      userName,
      otherUserId
    );
    
    return true;
  }
  
  /**
   * Reject a match
   */
  async rejectMatch(matchId, userId) {
    const matchRef = db.collection(collections.MATCHES).doc(matchId);
    const matchDoc = await matchRef.get();
    
    if (!matchDoc.exists) {
      throw new Error("Match not found");
    }
    
    const match = matchDoc.data();
    
    if (!match.participants.includes(userId)) {
      throw new Error("User not a participant in this match");
    }
    
    await matchRef.update({
      status: MATCH_STATUS.REJECTED,
      rejectedBy: userId,
      rejectedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    return true;
  }
  
  /**
   * Complete a delivery
   */
  async completeDelivery(matchId, userId) {
    const matchRef = db.collection(collections.MATCHES).doc(matchId);
    const matchDoc = await matchRef.get();
    
    if (!matchDoc.exists) {
      throw new Error("Match not found");
    }
    
    const match = matchDoc.data();
    
    if (!match.participants.includes(userId)) {
      throw new Error("User not a participant in this match");
    }
    
    const completableStatuses = [
      MATCH_STATUS.ACCEPTED,
      MATCH_STATUS.CONFIRMED,
      MATCH_STATUS.PICKED_UP,
      MATCH_STATUS.IN_TRANSIT,
      MATCH_STATUS.DELIVERED,
    ];

    if (!completableStatuses.includes(match.status)) {
      throw new Error("Match must be in an active state before completing");
    }
    
    // Update match
    await matchRef.update({
      status: MATCH_STATUS.COMPLETED,
      completedBy: userId,
      completedAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    // Update request status
    await db.collection(collections.REQUESTS).doc(match.requestId).update({
      // Keep in sync with the Flutter client model (RequestStatus.completed)
      status: "completed",
      updatedAt: FieldValue.serverTimestamp(),
    });
    
    // Notify other participant
    const otherUserId = match.participants.find((p) => p !== userId);
    await notificationService.sendDeliveryCompletedNotification(
      { id: matchId },
      otherUserId
    );
    
    return true;
  }
}

module.exports = new MatchingService();