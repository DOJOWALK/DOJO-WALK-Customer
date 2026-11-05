import '../../addresses/models/saved_address.dart';

/// Builds the immutable pickup-address payload stored with a booking.
///
/// Coordinates are included only when present, preserving compatibility with
/// saved addresses created before GPS coordinates were captured.
Map<String, dynamic> buildPickupAddressSnapshot(SavedAddress address) {
  return {
    'addressId': address.id,
    'label': address.label,
    'flatHouse': address.flatHouse,
    'buildingSociety': address.buildingSociety,
    'address': [
      address.flatHouse,
      address.buildingSociety,
    ]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join(', '),
    'area': address.area,
    'landmark': address.landmark,
    'city': address.city,
    'pincode': address.pincode,
    'pickupInstructions': address.pickupInstructions,
    'isDefault': address.isDefault,
    if (address.latitude != null) 'latitude': address.latitude,
    if (address.longitude != null) 'longitude': address.longitude,
  };
}
