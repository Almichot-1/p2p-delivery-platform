// Note: We're using UserModel from auth feature for profile data
// This file can be used for profile-specific extensions if needed

import '../../../auth/data/models/user_model.dart';

extension ProfileExtensions on UserModel {
  String get displayRole {
    switch (role) {
      case UserRole.requester:
        return 'Requester';
      case UserRole.traveler:
        return 'Traveler';
      case UserRole.both:
        return 'Requester & Traveler';
    }
  }

  String get verificationStatusDisplay {
    switch (verificationStatus) {
      case VerificationStatus.unverified:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Pending Verification';
      case VerificationStatus.verified:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
    }
  }

  bool get canPostTrips => role == UserRole.traveler || role == UserRole.both;

  bool get canPostRequests =>
      role == UserRole.requester || role == UserRole.both;
}
