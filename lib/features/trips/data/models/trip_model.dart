import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TripStatus { active, completed, cancelled }

class TripModel extends Equatable {
  const TripModel({
    required this.id,
    required this.travelerId,
    required this.travelerName,
    this.travelerPhoto,
    this.travelerRating = 0.0,
    required this.originCity,
    required this.originCountry,
    required this.destinationCity,
    required this.destinationCountry,
    required this.departureDate,
    this.returnDate,
    required this.availableCapacityKg,
    this.pricePerKg,
    this.acceptedItemTypes = const <String>[],
    this.notes,
    this.status = TripStatus.active,
    this.matchCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  final String travelerId;
  final String travelerName;
  final String? travelerPhoto;
  final double travelerRating;

  final String originCity;
  final String originCountry;
  final String destinationCity;
  final String destinationCountry;

  final DateTime departureDate;
  final DateTime? returnDate;

  final double availableCapacityKg;
  final double? pricePerKg;

  final List<String> acceptedItemTypes;
  final String? notes;

  final TripStatus status;
  final int matchCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TripModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Trip document is empty for id=${doc.id}');
    }

    DateTime? tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    TripStatus parseStatus(dynamic v) {
      final s = (v ?? '').toString();
      switch (s) {
        case 'completed':
          return TripStatus.completed;
        case 'cancelled':
          return TripStatus.cancelled;
        case 'active':
        default:
          return TripStatus.active;
      }
    }

    return TripModel(
      id: doc.id,
      travelerId: data['travelerId']?.toString() ?? '',
      travelerName: data['travelerName']?.toString() ?? '',
      travelerPhoto: data['travelerPhoto']?.toString(),
      travelerRating: (data['travelerRating'] as num?)?.toDouble() ?? 0.0,
      originCity: data['originCity']?.toString() ?? '',
      originCountry: data['originCountry']?.toString() ?? '',
      destinationCity: data['destinationCity']?.toString() ?? '',
      destinationCountry: data['destinationCountry']?.toString() ?? '',
      departureDate: tsToDate(data['departureDate']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      returnDate: tsToDate(data['returnDate']),
      availableCapacityKg: (data['availableCapacityKg'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (data['pricePerKg'] as num?)?.toDouble(),
      acceptedItemTypes: (data['acceptedItemTypes'] is Iterable)
          ? (data['acceptedItemTypes'] as Iterable)
              .map((e) => e.toString())
              .toList(growable: false)
          : const <String>[],
      notes: data['notes']?.toString(),
      status: parseStatus(data['status']),
      matchCount: (data['matchCount'] as num?)?.toInt() ?? 0,
      createdAt: tsToDate(data['createdAt']),
      updatedAt: tsToDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerPhoto': travelerPhoto,
      'travelerRating': travelerRating,
      'originCity': originCity,
      'originCountry': originCountry,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'departureDate': Timestamp.fromDate(departureDate),
      'returnDate': returnDate == null ? null : Timestamp.fromDate(returnDate!),
      'availableCapacityKg': availableCapacityKg,
      'pricePerKg': pricePerKg,
      'acceptedItemTypes': acceptedItemTypes,
      'notes': notes,
      'status': status.name,
      'matchCount': matchCount,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    }..removeWhere((key, value) => value == null);
  }

  TripModel copyWith({
    String? id,
    String? travelerId,
    String? travelerName,
    String? travelerPhoto,
    double? travelerRating,
    String? originCity,
    String? originCountry,
    String? destinationCity,
    String? destinationCountry,
    DateTime? departureDate,
    DateTime? returnDate,
    double? availableCapacityKg,
    double? pricePerKg,
    List<String>? acceptedItemTypes,
    String? notes,
    TripStatus? status,
    int? matchCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      travelerId: travelerId ?? this.travelerId,
      travelerName: travelerName ?? this.travelerName,
      travelerPhoto: travelerPhoto ?? this.travelerPhoto,
      travelerRating: travelerRating ?? this.travelerRating,
      originCity: originCity ?? this.originCity,
      originCountry: originCountry ?? this.originCountry,
      destinationCity: destinationCity ?? this.destinationCity,
      destinationCountry: destinationCountry ?? this.destinationCountry,
      departureDate: departureDate ?? this.departureDate,
      returnDate: returnDate ?? this.returnDate,
      availableCapacityKg: availableCapacityKg ?? this.availableCapacityKg,
      pricePerKg: pricePerKg ?? this.pricePerKg,
      acceptedItemTypes: acceptedItemTypes ?? this.acceptedItemTypes,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get _originLabel {
    final v = originCountry.trim();
    return v.isEmpty ? originCity : v;
  }

  String get _destinationLabel {
    final v = destinationCountry.trim();
    if (v.isNotEmpty && v != 'Ethiopia') return v;
    final fallback = destinationCity.trim();
    return fallback.isEmpty ? v : fallback;
  }

  String get routeDisplay => '$_originLabel → $_destinationLabel';

  bool get isUpcoming => departureDate.isAfter(DateTime.now());

  @override
  List<Object?> get props => <Object?>[
        id,
        travelerId,
        travelerName,
        travelerPhoto,
        travelerRating,
        originCity,
        originCountry,
        destinationCity,
        destinationCountry,
        departureDate,
        returnDate,
        availableCapacityKg,
        pricePerKg,
        acceptedItemTypes,
        notes,
        status,
        matchCount,
        createdAt,
        updatedAt,
      ];
}
