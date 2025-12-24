import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum RequestStatus { draft, active, matched, inProgress, completed, cancelled }

enum ItemCategory {
  documents,
  electronics,
  clothing,
  food,
  medicine,
  gifts,
  other
}

class RequestModel extends Equatable {
  final String id;
  final String requesterId;
  final String requesterName;
  final String? requesterPhoto;
  final double requesterRating;
  final String title;
  final String description;
  final ItemCategory category;
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
  final DateTime? updatedAt;

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
    this.imageUrls = const [],
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
    this.updatedAt,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterPhoto: data['requesterPhoto'],
      requesterRating: (data['requesterRating'] ?? 0.0).toDouble(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: ItemCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ItemCategory.other,
      ),
      weightKg: (data['weightKg'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      pickupCity: data['pickupCity'] ?? '',
      pickupCountry: data['pickupCountry'] ?? '',
      pickupAddress: data['pickupAddress'] ?? '',
      deliveryCity: data['deliveryCity'] ?? '',
      deliveryCountry: data['deliveryCountry'] ?? '',
      deliveryAddress: data['deliveryAddress'] ?? '',
      recipientName: data['recipientName'] ?? '',
      recipientPhone: data['recipientPhone'] ?? '',
      preferredDeliveryDate: data['preferredDeliveryDate'] != null
          ? (data['preferredDeliveryDate'] as Timestamp).toDate()
          : null,
      offeredPrice: data['offeredPrice']?.toDouble(),
      isUrgent: data['isUrgent'] ?? false,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => RequestStatus.active,
      ),
      matchedTripId: data['matchedTripId'],
      matchedTravelerId: data['matchedTravelerId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
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
      'preferredDeliveryDate': preferredDeliveryDate != null
          ? Timestamp.fromDate(preferredDeliveryDate!)
          : null,
      'offeredPrice': offeredPrice,
      'isUrgent': isUrgent,
      'status': status.name,
      'matchedTripId': matchedTripId,
      'matchedTravelerId': matchedTravelerId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  RequestModel copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhoto,
    double? requesterRating,
    String? title,
    String? description,
    ItemCategory? category,
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
      case ItemCategory.documents:
        return 'Documents';
      case ItemCategory.electronics:
        return 'Electronics';
      case ItemCategory.clothing:
        return 'Clothing';
      case ItemCategory.food:
        return 'Food Items';
      case ItemCategory.medicine:
        return 'Medicine';
      case ItemCategory.gifts:
        return 'Gifts';
      case ItemCategory.other:
        return 'Other';
    }
  }

  @override
  List<Object?> get props => [id, requesterId, title, status];
}
