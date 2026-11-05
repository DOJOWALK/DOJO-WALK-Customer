import 'package:flutter_test/flutter_test.dart';
import 'package:dojo_walk_customer/features/addresses/models/saved_address.dart';
import 'package:dojo_walk_customer/features/booking/models/pickup_address_snapshot.dart';

void main() {
  group('buildPickupAddressSnapshot', () {
    const baseAddress = SavedAddress(
      id: 'address-1',
      label: 'Home',
      flatHouse: 'Flat 101',
      buildingSociety: 'Example Society',
      area: 'Crossings Republik',
      city: 'Ghaziabad',
      pincode: '201016',
    );

    test('preserves both GPS coordinates when available', () {
      const address = SavedAddress(
        id: 'address-2',
        label: 'Home',
        flatHouse: 'Flat 101',
        area: 'Crossings Republik',
        city: 'Ghaziabad',
        pincode: '201016',
        latitude: 28.63,
        longitude: 77.37,
      );

      final snapshot = buildPickupAddressSnapshot(address);

      expect(snapshot['latitude'], 28.63);
      expect(snapshot['longitude'], 77.37);
      expect(snapshot['addressId'], 'address-2');
    });

    test('omits absent coordinates for legacy saved addresses', () {
      final snapshot = buildPickupAddressSnapshot(baseAddress);

      expect(snapshot.containsKey('latitude'), isFalse);
      expect(snapshot.containsKey('longitude'), isFalse);
      expect(snapshot['address'], 'Flat 101, Example Society');
    });

    test('preserves a single coordinate without inventing the other', () {
      const address = SavedAddress(
        label: 'Home',
        flatHouse: 'Flat 101',
        area: 'Crossings Republik',
        city: 'Ghaziabad',
        pincode: '201016',
        latitude: 28.63,
      );

      final snapshot = buildPickupAddressSnapshot(address);

      expect(snapshot['latitude'], 28.63);
      expect(snapshot.containsKey('longitude'), isFalse);
    });
  });
}
