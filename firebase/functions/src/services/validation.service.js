/**
 * Validation Service
 * Handles data validation
 */

const validator = require("validator");
const { LIMITS } = require("../utils/constants");

class ValidationService {
  /**
   * Validate trip data
   */
  validateTrip(data) {
    const errors = [];
    
    if (!data.originCity || data.originCity.length < 2) {
      errors.push("Origin city is required (min 2 characters)");
    }
    
    if (!data.originCountry || data.originCountry.length < 2) {
      errors.push("Origin country is required");
    }
    
    if (!data.destinationCity || data.destinationCity.length < 2) {
      errors.push("Destination city is required (min 2 characters)");
    }
    
    if (!data.destinationCountry || data.destinationCountry.length < 2) {
      errors.push("Destination country is required");
    }
    
    if (!data.departureDate) {
      errors.push("Departure date is required");
    } else {
      const depDate = new Date(data.departureDate);
      if (depDate <= new Date()) {
        errors.push("Departure date must be in the future");
      }
    }
    
    if (data.availableWeight === undefined || data.availableWeight <= 0) {
      errors.push("Available weight must be greater than 0");
    } else if (data.availableWeight > LIMITS.MAX_WEIGHT_KG) {
      errors.push(`Available weight cannot exceed ${LIMITS.MAX_WEIGHT_KG}kg`);
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
  
  /**
   * Validate request data
   */
  validateRequest(data) {
    const errors = [];
    
    if (!data.title || data.title.length < 5) {
      errors.push("Title is required (min 5 characters)");
    } else if (data.title.length > LIMITS.MAX_TITLE_LENGTH) {
      errors.push(`Title cannot exceed ${LIMITS.MAX_TITLE_LENGTH} characters`);
    }
    
    if (!data.description || data.description.length < 10) {
      errors.push("Description is required (min 10 characters)");
    } else if (data.description.length > LIMITS.MAX_DESCRIPTION_LENGTH) {
      errors.push(`Description cannot exceed ${LIMITS.MAX_DESCRIPTION_LENGTH} characters`);
    }
    
    if (!data.pickupCity || data.pickupCity.length < 2) {
      errors.push("Pickup city is required");
    }
    
    if (!data.deliveryCity || data.deliveryCity.length < 2) {
      errors.push("Delivery city is required");
    }
    
    if (!data.deliveryCountry || data.deliveryCountry.length < 2) {
      errors.push("Delivery country is required");
    }
    
    if (data.weight === undefined || data.weight <= 0) {
      errors.push("Weight must be greater than 0");
    } else if (data.weight > LIMITS.MAX_ITEM_WEIGHT_KG) {
      errors.push(`Weight cannot exceed ${LIMITS.MAX_ITEM_WEIGHT_KG}kg`);
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
  
  /**
   * Validate user profile data
   */
  validateUserProfile(data) {
    const errors = [];
    
    if (data.displayName !== undefined) {
      if (data.displayName.length < 2 || data.displayName.length > 100) {
        errors.push("Display name must be 2-100 characters");
      }
    }
    
    if (data.phone !== undefined && data.phone) {
      if (!validator.isMobilePhone(data.phone, "any")) {
        errors.push("Invalid phone number format");
      }
    }
    
    if (data.bio !== undefined && data.bio.length > 500) {
      errors.push("Bio cannot exceed 500 characters");
    }
    
    if (data.languages !== undefined) {
      if (!Array.isArray(data.languages) || data.languages.length > 10) {
        errors.push("Languages must be an array with max 10 items");
      }
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
  
  /**
   * Validate message
   */
  validateMessage(content) {
    const errors = [];
    
    if (!content || content.trim().length === 0) {
      errors.push("Message cannot be empty");
    } else if (content.length > LIMITS.MAX_MESSAGE_LENGTH) {
      errors.push(`Message cannot exceed ${LIMITS.MAX_MESSAGE_LENGTH} characters`);
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
  
  /**
   * Validate review
   */
  validateReview(rating, comment) {
    const errors = [];
    
    if (rating === undefined || rating < 1 || rating > 5) {
      errors.push("Rating must be between 1 and 5");
    }
    
    if (comment && comment.length > 1000) {
      errors.push("Comment cannot exceed 1000 characters");
    }
    
    return {
      isValid: errors.length === 0,
      errors,
    };
  }
}

module.exports = new ValidationService();