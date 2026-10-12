
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/saved_address.dart';

class AddressService {
  AddressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String get _uid {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please sign in to manage addresses.');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _addresses =>
      _firestore
          .collection('users')
          .doc(_uid)
          .collection('addresses');

  /// Returns addresses with the default address first,
  /// followed by the newest saved addresses.
  List<SavedAddress> _sortAddresses(
    List<SavedAddress> addresses,
  ) {
    addresses.sort((a, b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }

      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;

      return bTime.compareTo(aTime);
    });

    return addresses;
  }

  Stream<List<SavedAddress>> watchAddresses() {
    return _addresses.snapshots().map((snapshot) {
      final addresses = snapshot.docs
          .map(
            (doc) => SavedAddress.fromMap(
              doc.id,
              doc.data(),
            ),
          )
          .toList();

      return _sortAddresses(addresses);
    });
  }

  Future<List<SavedAddress>> getAddresses() async {
    final snapshot = await _addresses.get();

    final addresses = snapshot.docs
        .map(
          (doc) => SavedAddress.fromMap(
            doc.id,
            doc.data(),
          ),
        )
        .toList();

    return _sortAddresses(addresses);
  }

  /// Saves a new address or updates an existing address.
  ///
  /// Returns the Firestore document ID of the saved address.
  /// The first address automatically becomes the default address.
  Future<String> saveAddress(
    SavedAddress address, {
    bool makeDefault = false,
  }) async {
    final collection = _addresses;
    final isNew = address.id.trim().isEmpty;

    final DocumentReference<Map<String, dynamic>> ref =
        isNew ? collection.doc() : collection.doc(address.id);

    DocumentSnapshot<Map<String, dynamic>>? existingSnapshot;

    if (!isNew) {
      existingSnapshot = await ref.get();

      if (!existingSnapshot.exists) {
        throw StateError('This address no longer exists.');
      }
    }

    final allAddresses = await collection.get();

    final existingIsDefault =
        existingSnapshot?.data()?['isDefault'] == true;

    // Keep the current default when editing it.
    // The first address is automatically made default.
    final shouldBeDefault = makeDefault ||
        address.isDefault ||
        existingIsDefault ||
        (isNew && allAddresses.docs.isEmpty);

    final batch = _firestore.batch();

    // Ensure only the selected address remains default.
    if (shouldBeDefault) {
      for (final doc in allAddresses.docs) {
        if (doc.id != ref.id &&
            doc.data()['isDefault'] == true) {
          batch.update(doc.reference, {
            'isDefault': false,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    }

    final data = address
        .copyWith(isDefault: shouldBeDefault)
        .toMap(includeCreatedAt: isNew);

    batch.set(
      ref,
      data,
      SetOptions(merge: true),
    );

    await batch.commit();

    return ref.id;
  }

  /// Makes the selected address the default address.
  Future<void> setDefaultAddress(String addressId) async {
    final collection = _addresses;
    final selected = collection.doc(addressId);

    final selectedSnapshot = await selected.get();

    if (!selectedSnapshot.exists) {
      throw StateError('This address no longer exists.');
    }

    final snapshot = await collection.get();
    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isDefault': doc.id == addressId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Deletes an address.
  /// If it was the default, the newest remaining address becomes default.
  Future<void> deleteAddress(String addressId) async {
    final collection = _addresses;
    final selected = collection.doc(addressId);

    final selectedSnapshot = await selected.get();

    if (!selectedSnapshot.exists) {
      return;
    }

    final wasDefault =
        selectedSnapshot.data()?['isDefault'] == true;

    final snapshot = await collection.get();

    final remaining = snapshot.docs
        .where((doc) => doc.id != addressId)
        .toList();

    final batch = _firestore.batch();

    batch.delete(selected);

    if (wasDefault && remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final aCreatedAt = a.data()['createdAt'];
        final bCreatedAt = b.data()['createdAt'];

        final aTime = aCreatedAt is Timestamp
            ? aCreatedAt.millisecondsSinceEpoch
            : 0;

        final bTime = bCreatedAt is Timestamp
            ? bCreatedAt.millisecondsSinceEpoch
            : 0;

        return bTime.compareTo(aTime);
      });

      batch.update(remaining.first.reference, {
        'isDefault': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}
