import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RequestCategory {
  documents,
  electronics,
  clothing,
  food,
  medicine,
  other,
}

enum RequestStatus {
  active,
  matched,
  inProgress,
  completed,
  cancelled,
}

class RequestModel extends Equatable {
  const RequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    this.requesterPhoto,
    this.requesterRating = 0.0,
    required this.title,
    required this.description,
    required this.category,
    required this.weightKg,
    this.imageUrls = const <String>[],
    required this.pickupCity,
    required this.pickupCountry,
    required this.pickupAddress,
    required this.deliveryCity,
    required this.deliveryCountry,
    required this.deliveryAddress,
    required this.recipientName,
    required this.recipientPhone,
    this.preferredDeliveryDate,
    this.offeredPrice,
    this.isUrgent = false,
    this.status = RequestStatus.active,
    this.matchedTripId,
    this.matchedTravelerId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;

  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final double requesterRating;

  final String title;
  final String description;
  final RequestCategory category;
  final double weightKg;
  final List<String> imageUrls;

  final String pickupCity;
  final String pickupCountry;
  final String pickupAddress;

  final String deliveryCity;
  final String deliveryCountry;
  final String deliveryAddress;

  final String recipientName;
  final String recipientPhone;

  final DateTime? preferredDeliveryDate;
  final double? offeredPrice;
  final bool isUrgent;

  final RequestStatus status;

  final String? matchedTripId;
  final String? matchedTravelerId;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory RequestModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Request document is empty for id=${doc.id}');
    }

    DateTime? tsToDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    RequestCategory parseCategory(dynamic v) {
      final s = (v ?? '').toString();
      return RequestCategory.values
          .where((e) => e.name == s)
          .cast<RequestCategory?>()
          .firstWhere((_) => true, orElse: () => RequestCategory.other)!;
    }

    RequestStatus parseStatus(dynamic v) {
      final s = (v ?? '').toString();
      return RequestStatus.values
          .where((e) => e.name == s)
          .cast<RequestStatus?>()
          .firstWhere((_) => true, orElse: () => RequestStatus.active)!;
    }

    final createdAt =
        tsToDate(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final updatedAt = tsToDate(data['updatedAt']) ?? createdAt;

    return RequestModel(
      id: doc.id,
      requesterId: data['requesterId']?.toString() ?? '',
      requesterName: data['requesterName']?.toString() ?? '',
      requesterPhoto: data['requesterPhoto']?.toString(),
      requesterRating: (data['requesterRating'] as num?)?.toDouble() ?? 0.0,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      category: parseCategory(data['category']),
      weightKg: (data['weightKg'] as num?)?.toDouble() ?? 0.0,
      imageUrls: (data['imageUrls'] is Iterable)
          ? (data['imageUrls'] as Iterable)
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false)
          : const <String>[],
      pickupCity: data['pickupCity']?.toString() ?? '',
      pickupCountry: data['pickupCountry']?.toString() ?? '',
      pickupAddress: data['pickupAddress']?.toString() ?? '',
      deliveryCity: data['deliveryCity']?.toString() ?? '',
      deliveryCountry: data['deliveryCountry']?.toString() ?? '',
      deliveryAddress: data['deliveryAddress']?.toString() ?? '',
      recipientName: data['recipientName']?.toString() ?? '',
      recipientPhone: data['recipientPhone']?.toString() ?? '',
      preferredDeliveryDate: tsToDate(data['preferredDeliveryDate']),
      offeredPrice: (data['offeredPrice'] as num?)?.toDouble(),
      isUrgent: (data['isUrgent'] as bool?) ?? false,
      status: parseStatus(data['status']),
      matchedTripId: data['matchedTripId']?.toString(),
      matchedTravelerId: data['matchedTravelerId']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhoto': requesterPhoto,
      'requesterRating': requesterRating,
      'title': title,
      'description': description,
      'category': category.name,
      'weightKg': weightKg,
      'imageUrls': imageUrls,
      'pickupCity': pickupCity,
      'pickupCountry': pickupCountry,
      'pickupAddress': pickupAddress,
      'deliveryCity': deliveryCity,
      'deliveryCountry': deliveryCountry,
      'deliveryAddress': deliveryAddress,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      'preferredDeliveryDate': preferredDeliveryDate == null
          ? null
          : Timestamp.fromDate(preferredDeliveryDate!),
      'offeredPrice': offeredPrice,
      'isUrgent': isUrgent,
      'status': status.name,
      'matchedTripId': matchedTripId,
      'matchedTravelerId': matchedTravelerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    }..removeWhere((key, value) => value == null);
  }

  RequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhoto,
    double? requesterRating,
    String? title,
    String? description,
    RequestCategory? category,
    double? weightKg,
    List<String>? imageUrls,
    String? pickupCity,
    String? pickupCountry,
    String? pickupAddress,
    String? deliveryCity,
    String? deliveryCountry,
    String? deliveryAddress,
    String? recipientName,
    String? recipientPhone,
    DateTime? preferredDeliveryDate,
    double? offeredPrice,
    bool? isUrgent,
    RequestStatus? status,
    String? matchedTripId,
    String? matchedTravelerId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhoto: requesterPhoto ?? this.requesterPhoto,
      requesterRating: requesterRating ?? this.requesterRating,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      weightKg: weightKg ?? this.weightKg,
      imageUrls: imageUrls ?? this.imageUrls,
      pickupCity: pickupCity ?? this.pickupCity,
      pickupCountry: pickupCountry ?? this.pickupCountry,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryCity: deliveryCity ?? this.deliveryCity,
      deliveryCountry: deliveryCountry ?? this.deliveryCountry,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      recipientName: recipientName ?? this.recipientName,
      recipientPhone: recipientPhone ?? this.recipientPhone,
      preferredDeliveryDate:
          preferredDeliveryDate ?? this.preferredDeliveryDate,
      offeredPrice: offeredPrice ?? this.offeredPrice,
      isUrgent: isUrgent ?? this.isUrgent,
      status: status ?? this.status,
      matchedTripId: matchedTripId ?? this.matchedTripId,
      matchedTravelerId: matchedTravelerId ?? this.matchedTravelerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get routeDisplay => '$pickupCity → $deliveryCity';

  String get categoryDisplay {
    switch (category) {
      case RequestCategory.documents:
        return 'Documents';
      case RequestCategory.electronics:
        return 'Electronics';
      case RequestCategory.clothing:
        return 'Clothing';
      case RequestCategory.food:
        return 'Food';
      case RequestCategory.medicine:
        return 'Medicine';
      case RequestCategory.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        requesterId,
        requesterName,
        requesterPhoto,
        requesterRating,
        title,
        description,
        category,
        weightKg,
        imageUrls,
        pickupCity,
        pickupCountry,
        pickupAddress,
        deliveryCity,
        deliveryCountry,
        deliveryAddress,
        recipientName,
        recipientPhone,
        preferredDeliveryDate,
        offeredPrice,
        isUrgent,
        status,
        matchedTripId,
        matchedTravelerId,
        createdAt,
        updatedAt,
      ];
}
