import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const Color dogsOrange = Color(0xFFFF7900);
const Color dogsBackground = Color(0xFFFFFAF5);
const Color dogsText = Color(0xFF202020);
const Color dogsMuted = Color(0xFF777777);

class MyDogsScreen extends StatelessWidget {
  const MyDogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: dogsBackground,
      appBar: AppBar(
        backgroundColor: dogsBackground,
        elevation: 0,
        title: const Text(
          'My Dogs',
          style: TextStyle(
            color: dogsText,
            fontWeight: FontWeight.w900,
            fontSize: 23,
          ),
        ),
        iconTheme: const IconThemeData(color: dogsText),
      ),
      body: user == null
          ? _buildLoginMessage()
          : _buildDogsList(user.uid),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openDogForm(context),
              backgroundColor: dogsOrange,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Dog',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
    );
  }

  Widget _buildLoginMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              size: 58,
              color: dogsOrange,
            ),
            SizedBox(height: 16),
            Text(
              'Login Required',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: dogsText,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Please log in to manage your dogs.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dogsMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  CollectionReference<Map<String, dynamic>> _pets(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets');
  }

  Widget _buildDogsList(String uid) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _pets(uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _message(
            icon: Icons.cloud_off_rounded,
            title: 'Unable to load dogs',
            subtitle:
                'Please check your internet connection and Firestore permissions.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: dogsOrange),
          );
        }

        final documents = snapshot.data?.docs ?? [];

        if (documents.isEmpty) {
          return _message(
            icon: Icons.pets_rounded,
            title: 'No Dogs Added Yet',
            subtitle:
                'Add your dog’s details to make future bookings easier.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          children: [
            Text(
              '${documents.length} ${documents.length == 1 ? 'Dog' : 'Dogs'}',
              style: const TextStyle(
                fontSize: 14,
                color: dogsMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            ...documents.map((document) {
              final data = document.data();

              return _dogCard(
                context: context,
                uid: uid,
                dogId: document.id,
                data: data,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _dogCard({
    required BuildContext context,
    required String uid,
    required String dogId,
    required Map<String, dynamic> data,
  }) {
    final name = (data['name'] ?? 'My Dog').toString();
    final breed = (data['breed'] ?? '').toString();
    final age = (data['age'] ?? '').toString();
    final size = (data['size'] ?? '').toString();
    final gender = (data['gender'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 62,
                width: 62,
                decoration: BoxDecoration(
                  color: dogsOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.pets_rounded,
                  size: 32,
                  color: dogsOrange,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: dogsText,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      breed.isEmpty ? 'Breed not added' : breed,
                      style: const TextStyle(
                        fontSize: 13,
                        color: dogsMuted,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (age.isNotEmpty) '$age years',
                        if (size.isNotEmpty) size,
                        if (gender.isNotEmpty &&
                            gender != 'Not specified')
                          gender,
                      ].join(' • '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: dogsMuted,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _openDogForm(
                      context,
                      dogId: dogId,
                      existingData: data,
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(context, uid, dogId, name);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Dog'),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete Dog'),
                  ),
                ],
              ),
            ],
          ),
          if ((data['notes'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dogsBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['notes'].toString(),
                style: const TextStyle(
                  color: dogsMuted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 105,
              width: 105,
              decoration: BoxDecoration(
                color: dogsOrange.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: dogsOrange),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dogsText,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dogsMuted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openDogForm(
    BuildContext context, {
    String? dogId,
    Map<String, dynamic>? existingData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: (existingData?['name'] ?? '').toString(),
    );
    final breedController = TextEditingController(
      text: (existingData?['breed'] ?? '').toString(),
    );
    final ageController = TextEditingController(
      text: (existingData?['age'] ?? '').toString(),
    );
    final notesController = TextEditingController(
      text: (existingData?['notes'] ?? '').toString(),
    );

    String size = (existingData?['size'] ?? 'Medium').toString();
    String gender =
        (existingData?['gender'] ?? 'Not specified').toString();

    if (!['Small', 'Medium', 'Large', 'Extra Large'].contains(size)) {
      size = 'Medium';
    }

    if (!['Not specified', 'Male', 'Female'].contains(gender)) {
      gender = 'Not specified';
    }

    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: dogsBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveDog() async {
              if (saving) return;

              if (!formKey.currentState!.validate()) return;

              setSheetState(() => saving = true);

              final data = <String, dynamic>{
                'name': nameController.text.trim(),
                'breed': breedController.text.trim(),
                'age': ageController.text.trim(),
                'size': size,
                'gender': gender,
                'notes': notesController.text.trim(),
                'updatedAt': FieldValue.serverTimestamp(),
              };

              try {
                final collection = _pets(user.uid);

                if (dogId == null) {
                  data['createdAt'] = FieldValue.serverTimestamp();
                  await collection.add(data);
                } else {
                  await collection.doc(dogId).update(data);
                }

                if (!context.mounted) return;

                Navigator.pop(sheetContext);

                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text(
                      dogId == null
                          ? 'Dog added successfully.'
                          : 'Dog details updated.',
                    ),
                    backgroundColor: dogsOrange,
                  ),
                );
              } catch (error) {
                setSheetState(() => saving = false);

                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(
                    content: Text('Could not save dog: $error'),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 22,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        dogId == null ? 'Add Your Dog' : 'Edit Dog',
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: dogsText,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _fieldLabel('Dog Name *'),
                      TextFormField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('e.g. Bruno'),
                        validator: (value) {
                          final name = value?.trim() ?? '';

                          if (name.isEmpty) {
                            return 'Please enter your dog’s name';
                          }

                          if (name.length > 50) {
                            return 'Name must be under 50 characters';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _fieldLabel('Breed'),
                      TextFormField(
                        controller: breedController,
                        textCapitalization: TextCapitalization.words,
                        decoration: _inputDecoration('e.g. Labrador or Indie'),
                      ),
                      const SizedBox(height: 15),
                      _fieldLabel('Age in years'),
                      TextFormField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration('e.g. 2'),
                        validator: (value) {
                          final text = value?.trim() ?? '';

                          if (text.isEmpty) return null;

                          final age = int.tryParse(text);

                          if (age == null || age < 0 || age > 40) {
                            return 'Enter a whole number from 0 to 40';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      _fieldLabel('Dog Size'),
                      DropdownButtonFormField<String>(
                        initialValue: size,
                        isExpanded: true,
                        decoration: _inputDecoration('Select size'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Small',
                            child: Text('Small'),
                          ),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(
                            value: 'Large',
                            child: Text('Large'),
                          ),
                          DropdownMenuItem(
                            value: 'Extra Large',
                            child: Text('Extra Large'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => size = value);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      _fieldLabel('Gender'),
                      DropdownButtonFormField<String>(
                        initialValue: gender,
                        isExpanded: true,
                        decoration: _inputDecoration('Select gender'),
                        items: const [
                          DropdownMenuItem(
                            value: 'Not specified',
                            child: Text('Prefer not to specify'),
                          ),
                          DropdownMenuItem(
                            value: 'Male',
                            child: Text('Male'),
                          ),
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => gender = value);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      _fieldLabel('Special Instructions'),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        maxLength: 300,
                        decoration: _inputDecoration(
                          'Behaviour, leash needs or care instructions',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: saving ? null : saveDog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dogsOrange,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                dogsOrange.withValues(alpha: 0.5),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: saving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  dogId == null ? 'Save Dog' : 'Update Dog',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    breedController.dispose();
    ageController.dispose();
    notesController.dispose();
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String uid,
    String dogId,
    String dogName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Dog?'),
        content: Text(
          'Are you sure you want to delete $dogName?',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _pets(uid).doc(dogId).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dog deleted.'),
          backgroundColor: dogsOrange,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete dog: $error')),
      );
    }
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          color: dogsText,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Color(0xFFE7E7E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: dogsOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
