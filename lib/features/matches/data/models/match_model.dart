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
  cancelled,
}

class MatchModel extends Equatable {
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
    this.agreedPrice,
    required this.status,
    required this.participants,
    required this.createdAt,
    required this.updatedAt,
    this.confirmedAt,
    this.completedAt,
  });

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
  final String route; // "DC → Addis"
  final DateTime tripDate;

  final double? agreedPrice;

  final MatchStatus status;

  /// Includes travelerId and requesterId.
  final List<String> participants;

  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? confirmedAt;
  final DateTime? completedAt;

  static DateTime _tsToDate(dynamic v, {required DateTime fallback}) {
    if (v is Timestamp) return v.toDate();
    return fallback;
  }

  static DateTime? _tsToNullableDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static MatchStatus _parseStatus(dynamic v) {
    final s = (v ?? '').toString();
    for (final status in MatchStatus.values) {
      if (status.name == s) return status;
    }
    return MatchStatus.pending;
  }

  factory MatchModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Match document is empty for id=${doc.id}');
    }

    final createdFallback = DateTime.now();

    final travelerId = data['travelerId']?.toString() ?? '';
    final requesterId = data['requesterId']?.toString() ?? '';

    final participants = (data['participants'] is Iterable)
        ? (data['participants'] as Iterable)
            .map((e) => e.toString())
            .toList(growable: false)
        : <String>[travelerId, requesterId]
            .where((e) => e.isNotEmpty)
            .toList(growable: false);

    return MatchModel(
      id: data['id']?.toString() ?? doc.id,
      tripId: data['tripId']?.toString() ?? '',
      requestId: data['requestId']?.toString() ?? '',
      travelerId: travelerId,
      travelerName: data['travelerName']?.toString() ?? '',
      travelerPhoto: data['travelerPhoto']?.toString(),
      requesterId: requesterId,
      requesterName: data['requesterName']?.toString() ?? '',
      requesterPhoto: data['requesterPhoto']?.toString(),
      itemTitle: data['itemTitle']?.toString() ?? '',
      route: data['route']?.toString() ?? '',
      tripDate: _tsToDate(
        data['tripDate'],
        fallback: createdFallback,
      ),
      agreedPrice: (data['agreedPrice'] as num?)?.toDouble(),
      status: _parseStatus(data['status']),
      participants: participants,
      createdAt: _tsToDate(data['createdAt'], fallback: createdFallback),
      updatedAt: _tsToDate(data['updatedAt'], fallback: createdFallback),
      confirmedAt: _tsToNullableDate(data['confirmedAt']),
      completedAt: _tsToNullableDate(data['completedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'id': id,
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
      'updatedAt': Timestamp.fromDate(updatedAt),
      'confirmedAt':
          confirmedAt == null ? null : Timestamp.fromDate(confirmedAt!),
      'completedAt':
          completedAt == null ? null : Timestamp.fromDate(completedAt!),
    }..removeWhere((_, v) => v == null);
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

  String getOtherParticipantName(String currentUserId) {
    if (currentUserId == travelerId) return requesterName;
    return travelerName;
  }

  String getOtherParticipantPhoto(String currentUserId) {
    if (currentUserId == travelerId) return requesterPhoto ?? '';
    return travelerPhoto ?? '';
  }

  bool isParticipant(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return false;
    return participants.contains(id);
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        tripId,
        requestId,
        travelerId,
        travelerName,
        travelerPhoto,
        requesterId,
        requesterName,
        requesterPhoto,
        itemTitle,
        route,
        tripDate,
        agreedPrice,
        status,
        participants,
        createdAt,
        updatedAt,
        confirmedAt,
        completedAt,
      ];
}
