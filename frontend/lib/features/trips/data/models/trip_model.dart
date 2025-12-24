import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TripStatus { draft, active, completed, cancelled }

class TripModel extends Equatable {
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
  final double pricePerKg;
  final String? notes;
  final List<String> acceptedItemTypes;
  final TripStatus status;
  final int matchCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    this.pricePerKg = 0.0,
    this.notes,
    this.acceptedItemTypes = const [],
    this.status = TripStatus.active,
    this.matchCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel(
      id: doc.id,
      travelerId: data['travelerId'] ?? '',
      travelerName: data['travelerName'] ?? '',
      travelerPhoto: data['travelerPhoto'],
      travelerRating: (data['travelerRating'] ?? 0.0).toDouble(),
      originCity: data['originCity'] ?? '',
      originCountry: data['originCountry'] ?? '',
      destinationCity: data['destinationCity'] ?? '',
      destinationCountry: data['destinationCountry'] ?? '',
      departureDate: (data['departureDate'] as Timestamp).toDate(),
      returnDate: data['returnDate'] != null
          ? (data['returnDate'] as Timestamp).toDate()
          : null,
      availableCapacityKg: (data['availableCapacityKg'] ?? 0.0).toDouble(),
      pricePerKg: (data['pricePerKg'] ?? 0.0).toDouble(),
      notes: data['notes'],
      acceptedItemTypes: List<String>.from(data['acceptedItemTypes'] ?? []),
      status: TripStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TripStatus.active,
      ),
      matchCount: data['matchCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'travelerId': travelerId,
      'travelerName': travelerName,
      'travelerPhoto': travelerPhoto,
      'travelerRating': travelerRating,
      'originCity': originCity,
      'originCountry': originCountry,
      'destinationCity': destinationCity,
      'destinationCountry': destinationCountry,
      'departureDate': Timestamp.fromDate(departureDate),
      'returnDate': returnDate != null ? Timestamp.fromDate(returnDate!) : null,
      'availableCapacityKg': availableCapacityKg,
      'pricePerKg': pricePerKg,
      'notes': notes,
      'acceptedItemTypes': acceptedItemTypes,
      'status': status.name,
      'matchCount': matchCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
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
    String? notes,
    List<String>? acceptedItemTypes,
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
      notes: notes ?? this.notes,
      acceptedItemTypes: acceptedItemTypes ?? this.acceptedItemTypes,
      status: status ?? this.status,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get routeDisplay => '$originCity → $destinationCity';

  bool get isUpcoming => departureDate.isAfter(DateTime.now());

  @override
  List<Object?> get props => [
        id,
        travelerId,
        originCity,
        destinationCity,
        departureDate,
        status,
      ];
}
