import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum MatchStatus {
  pending,
  accepted,
  rejected,
  confirmed,
  pickedUp,
  inTransit,
  delivered,
  completed,
  cancelled
}

class MatchModel extends Equatable {
  final String id;
  final String tripId;
  final String requestId;
  final String travelerId;
  final String travelerName;
  final String? travelerPhoto;
  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final String itemTitle;
  final String route;
  final DateTime tripDate;
  final double agreedPrice;
  final MatchStatus status;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  const MatchModel({
    required this.id,
    required this.tripId,
    required this.requestId,
    required this.travelerId,
    required this.travelerName,
    this.travelerPhoto,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhoto,
    required this.itemTitle,
    required this.route,
    required this.tripDate,
    this.agreedPrice = 0.0,
    this.status = MatchStatus.pending,
    required this.participants,
    required this.createdAt,
    this.updatedAt,
    this.confirmedAt,
    this.completedAt,
  });

  factory MatchModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MatchModel(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      requestId: data['requestId'] ?? '',
      travelerId: data['travelerId'] ?? '',
      travelerName: data['travelerName'] ?? '',
      travelerPhoto: data['travelerPhoto'],
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterPhoto: data['requesterPhoto'],
      itemTitle: data['itemTitle'] ?? '',
      route: data['route'] ?? '',
      tripDate: (data['tripDate'] as Timestamp).toDate(),
      agreedPrice: (data['agreedPrice'] ?? 0.0).toDouble(),
      status: MatchStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MatchStatus.pending,
      ),
      participants: List<String>.from(data['participants'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      confirmedAt: (data['confirmedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'requestId': requestId,
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerPhoto': travelerPhoto,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhoto': requesterPhoto,
      'itemTitle': itemTitle,
      'route': route,
      'tripDate': Timestamp.fromDate(tripDate),
      'agreedPrice': agreedPrice,
      'status': status.name,
      'participants': participants,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
      'confirmedAt':
          confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  MatchModel copyWith({
    String? id,
    String? tripId,
    String? requestId,
    String? travelerId,
    String? travelerName,
    String? travelerPhoto,
    String? requesterId,
    String? requesterName,
    String? requesterPhoto,
    String? itemTitle,
    String? route,
    DateTime? tripDate,
    double? agreedPrice,
    MatchStatus? status,
    List<String>? participants,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? confirmedAt,
    DateTime? completedAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      requestId: requestId ?? this.requestId,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      travelerPhoto: travelerPhoto ?? this.travelerPhoto,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhoto: requesterPhoto ?? this.requesterPhoto,
      itemTitle: itemTitle ?? this.itemTitle,
      route: route ?? this.route,
      tripDate: tripDate ?? this.tripDate,
      agreedPrice: agreedPrice ?? this.agreedPrice,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool isParticipant(String userId) => participants.contains(userId);

  String getOtherParticipantName(String currentUserId) {
    return currentUserId == travelerId ? requesterName : travelerName;
  }

  String? getOtherParticipantPhoto(String currentUserId) {
    return currentUserId == travelerId ? requesterPhoto : travelerPhoto;
  }

  @override
  List<Object?> get props => [id, tripId, requestId, status];
}
