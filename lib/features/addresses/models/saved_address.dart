
import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAddress {
  final String id;
  final String label;
  final String flatHouse;
  final String buildingSociety;
  final String area;
  final String landmark;
  final String city;
  final String pincode;
  final String pickupInstructions;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;

  const SavedAddress({
    this.id = '',
    required this.label,
    required this.flatHouse,
    this.buildingSociety = '',
    required this.area,
    this.landmark = '',
    required this.city,
    required this.pincode,
    this.pickupInstructions = '',
    this.latitude,
    this.longitude,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap({bool includeCreatedAt = false}) {
    return {
      'label': label,
      'flatHouse': flatHouse,
      'buildingSociety': buildingSociety,
      'area': area,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'pickupInstructions': pickupInstructions,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'updatedAt': FieldValue.serverTimestamp(),
      if (includeCreatedAt)
        'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory SavedAddress.fromMap(
    String id,
    Map<String, dynamic> data,
  ) {
    double? toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    return SavedAddress(
      id: id,
      label: data['label']?.toString() ?? 'Home',
      flatHouse: data['flatHouse']?.toString() ??
          data['address']?.toString() ?? '',
      buildingSociety: data['buildingSociety']?.toString() ?? '',
      area: data['area']?.toString() ?? '',
      landmark: data['landmark']?.toString() ?? '',
      city: data['city']?.toString() ?? '',
      pincode: data['pincode']?.toString() ?? '',
      pickupInstructions:
          data['pickupInstructions']?.toString() ?? '',
      latitude: toDouble(data['latitude']),
      longitude: toDouble(data['longitude']),
      isDefault: data['isDefault'] == true,
      createdAt: data['createdAt'] is Timestamp
          ? data['createdAt'] as Timestamp
          : null,
      updatedAt: data['updatedAt'] is Timestamp
          ? data['updatedAt'] as Timestamp
          : null,
    );
  }

  Map<String, dynamic> toBookingSnapshot() {
    return {
      'label': label,
      'flatHouse': flatHouse,
      'buildingSociety': buildingSociety,
      'address': flatHouse,
      'area': area,
      'landmark': landmark,
      'city': city,
      'pincode': pincode,
      'pickupInstructions': pickupInstructions,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  SavedAddress copyWith({
    String? id,
    String? label,
    String? flatHouse,
    String? buildingSociety,
    String? area,
    String? landmark,
    String? city,
    String? pincode,
    String? pickupInstructions,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) {
    return SavedAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      flatHouse: flatHouse ?? this.flatHouse,
      buildingSociety: buildingSociety ?? this.buildingSociety,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      pickupInstructions:
          pickupInstructions ?? this.pickupInstructions,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
