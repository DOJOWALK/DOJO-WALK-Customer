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
      _firestore.collection('users').doc(_uid).collection('addresses');

  Stream<List<SavedAddress>> watchAddresses() {
    return _addresses.snapshots().map((snapshot) {
      final addresses = snapshot.docs
          .map((doc) => SavedAddress.fromMap(doc.id, doc.data()))
          .toList();

      addresses.sort((a, b) {
        if (a.isDefault != b.isDefault) {
          return a.isDefault ? -1 : 1;
        }

        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;

        return bTime.compareTo(aTime);
      });

      return addresses;
    });
  }

  Future<List<SavedAddress>> getAddresses() async {
    final snapshot = await _addresses.get();

    final addresses = snapshot.docs
        .map((doc) => SavedAddress.fromMap(doc.id, doc.data()))
        .toList();

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

  Future<String> saveAddress(
    SavedAddress address, {
    bool makeDefault = false,
  }) async {
    final collection = _addresses;
    final isNew = address.id.isEmpty;
    final ref = isNew ? collection.doc() : collection.doc(address.id);

    final existingSnapshot = isNew ? null : await ref.get();

    if (!isNew && !(existingSnapshot?.exists ?? false)) {
      throw StateError('This address no longer exists.');
    }

    final allAddresses = await collection.get();

    // Editing keeps the existing default state unless the caller
    // explicitly changes it through makeDefault or address.isDefault.
    final existingIsDefault =
        existingSnapshot?.data()?['isDefault'] == true;

    final shouldBeDefault = makeDefault ||
        address.isDefault ||
        (isNew && allAddresses.docs.isEmpty) ||
        (!isNew && existingIsDefault);

    final batch = _firestore.batch();

    if (shouldBeDefault) {
      for (final doc in allAddresses.docs) {
        if (doc.id != ref.id && doc.data()['isDefault'] == true) {
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

    batch.set(ref, data, SetOptions(merge: true));

    await batch.commit();

    return ref.id;
  }

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

  Future<void> deleteAddress(String addressId) async {
    final collection = _addresses;
    final selected = collection.doc(addressId);
    final selectedSnapshot = await selected.get();

    if (!selectedSnapshot.exists) {
      return;
    }

    final wasDefault = selectedSnapshot.data()?['isDefault'] == true;
    final snapshot = await collection.get();

    final remaining =
        snapshot.docs.where((doc) => doc.id != addressId).toList();

    final batch = _firestore.batch();

    batch.delete(selected);

    if (wasDefault && remaining.isNotEmpty) {
      remaining.sort((a, b) {
        final aTime = (a.data()['createdAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;
        final bTime = (b.data()['createdAt'] as Timestamp?)
                ?.millisecondsSinceEpoch ??
            0;

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
