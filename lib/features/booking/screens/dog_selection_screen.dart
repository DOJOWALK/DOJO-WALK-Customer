import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/screens/my_dogs_screen.dart';
import 'choose_walk_screen.dart';
import 'pickup_address_selection_screen.dart';
import '../../../app/theme.dart';
import '../../../app/locale_controller.dart';

const Color dogSelectionOrange = DojoWalkTheme.primary;
const Color dogSelectionBackground = DojoWalkTheme.background;
const Color dogSelectionText = DojoWalkTheme.text;
const Color dogSelectionMuted = DojoWalkTheme.mutedText;

class DogSelectionScreen extends StatefulWidget {
  final WalkBookingType walkType;
  final Map<String, dynamic> schedule;

  const DogSelectionScreen({
    super.key,
    required this.walkType,
    required this.schedule,
  });

  @override
  State<DogSelectionScreen> createState() =>
      _DogSelectionScreenState();
}

class _DogSelectionScreenState extends State<DogSelectionScreen> {
  String? _selectedDogId;
  Map<String, dynamic>? _selectedDog;

  bool _isContinuing = false;
  bool _isOpeningDogs = false;

  User? get _user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    appLocale.addListener(_onLocaleChanged);
  }

  @override
  void dispose() {
    appLocale.removeListener(_onLocaleChanged);
    super.dispose();
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  String _text(String en, String hi, String bn) =>
      appText(en: en, hi: hi, bn: bn);

  Stream<QuerySnapshot<Map<String, dynamic>>> _watchDogs() {
    final user = _user;

    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('pets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  String _dogName(Map<String, dynamic> dog) {
    return (dog['name'] ?? dog['petName'] ?? 'Unnamed Dog')
        .toString()
        .trim();
  }

  String _dogBreed(Map<String, dynamic> dog) {
    final breed = (dog['breed'] ?? '').toString().trim();
    return breed.isEmpty ? _text('Breed not provided', 'नस्ल की जानकारी नहीं दी गई', 'জাতের তথ্য দেওয়া হয়নি') : breed;
  }

  String _dogGender(Map<String, dynamic> dog) {
    final gender = (dog['gender'] ?? '').toString().trim();
    return gender.isEmpty ? _text('Not specified', 'नहीं बताया गया', 'উল্লেখ করা হয়নি') : gender;
  }

  String _dogAge(Map<String, dynamic> dog) {
    final age = dog['age'];

    if (age != null && age.toString().trim().isNotEmpty) {
      return age.toString();
    }

    final dob = dog['dateOfBirth'];

    if (dob is Timestamp) {
      final birthDate = dob.toDate();
      final today = DateTime.now();

      var years = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month &&
              today.day < birthDate.day)) {
        years--;
      }

      if (years >= 0) {
        return _text('$years years', '$years साल', '$years বছর');
      }
    }

    return _text('Age not provided', 'उम्र की जानकारी नहीं दी गई', 'বয়সের তথ্য দেওয়া হয়নি');
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addDog() async {
    if (_isOpeningDogs) return;

    setState(() => _isOpeningDogs = true);

    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MyDogsScreen(),
        ),
      );

      if (!mounted) return;

      // Refresh the screen after returning from My Dogs.
      setState(() {});
    } catch (e) {
      _showMessage(_text('Could not open dog details. Please try again.', 'डॉग की जानकारी नहीं खुल सकी। दोबारा कोशिश करें।', 'কুকুরের তথ্য খোলা যায়নি। আবার চেষ্টা করুন।'));
    } finally {
      if (mounted) {
        setState(() => _isOpeningDogs = false);
      }
    }
  }

  Future<void> _continue() async {
    if (_isContinuing) return;

    final user = _user;

    if (user == null) {
      _showMessage(_text('Please log in first.', 'पहले लॉग इन करें।', 'আগে লগ ইন করুন।'));
      return;
    }

    final dogId = _selectedDogId;
    final selectedDog = _selectedDog;

    if (dogId == null || selectedDog == null) {
      _showMessage(_text('Please select a dog.', 'कृपया अपना डॉग चुनें।', 'একটি কুকুর বেছে নিন।'));
      return;
    }

    setState(() => _isContinuing = true);

    try {
      // Verify the selected dog still exists in the customer's account.
      final dogDocument = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('pets')
          .doc(dogId)
          .get();

      if (!dogDocument.exists) {
        if (mounted) {
          setState(() {
            _selectedDogId = null;
            _selectedDog = null;
          });
        }

        throw StateError(
          _text('This dog is no longer in your saved list. Please select again.', 'यह डॉग अब आपकी सेव की गई सूची में नहीं है। दोबारा चुनें।', 'এই কুকুরটি আর সংরক্ষিত তালিকায় নেই। আবার বেছে নিন.'),
        );
      }

      final savedDog = dogDocument.data() ?? <String, dynamic>{};

      final name = _dogName(savedDog);

      if (name.isEmpty || name == 'Unnamed Dog') {
        throw StateError(
          _text('This dog has no name. Update its details first.', 'इस डॉग का नाम उपलब्ध नहीं है। पहले उसकी जानकारी अपडेट करें।', 'এই কুকুরের নাম নেই। আগে তথ্য আপডেট করুন.'),
        );
      }

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PickupAddressSelectionScreen(
            walkType: widget.walkType,
            schedule: widget.schedule,
            dogDetails: {
              ...savedDog,
              'dogId': dogId,
              'name': name,
            },
          ),
        ),
      );
    } on StateError catch (e) {
      _showMessage(e.message.toString());
    } on FirebaseException catch (e) {
      _showMessage(
        e.code == 'permission-denied'
            ? _text('Could not access dog details. Please try again.', 'डॉग की जानकारी नहीं खुल सकी। दोबारा कोशिश करें।', 'কুকুরের তথ্য খোলা যায়নি। আবার চেষ্টা করুন।')
            : _text('Could not load dog details. Please try again.', 'डॉग की जानकारी लोड नहीं हुई। दोबारा कोशिश करें।', 'কুকুরের তথ্য লোড হয়নি। আবার চেষ্টা করুন.'),
      );
    } catch (e) {
      _showMessage(_text('Could not continue. Please try again.', 'आगे नहीं बढ़ सके। दोबारा कोशिश करें।', 'এগোনো যায়নি। আবার চেষ্টা করুন।'));
    } finally {
      if (mounted) {
        setState(() => _isContinuing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return Scaffold(
        backgroundColor: dogSelectionBackground,
        appBar: AppBar(
          backgroundColor: dogSelectionOrange,
          foregroundColor: Colors.white,
          title: Text(_text('Select Your Dog', 'अपना डॉग चुनें', 'আপনার কুকুর বেছে নিন')),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              _text('Please log in to select a dog.', 'डॉग चुनने के लिए पहले लॉग इन करें।', 'কুকুর বেছে নিতে আগে লগ ইন করুন.'),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: dogSelectionBackground,
      appBar: AppBar(
        backgroundColor: dogSelectionOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _text('Select Your Dog', 'अपना डॉग चुनें', 'আপনার কুকুর বেছে নিন'),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<
                  QuerySnapshot<Map<String, dynamic>>>(
                stream: _watchDogs(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 44,
                              color: dogSelectionOrange,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              _text('Could not load dog details.', 'डॉग की जानकारी लोड नहीं हो सकी।', 'কুকুরের তথ্য লোড করা যায়নি.'),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: dogSelectionMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () => setState(() {}),
                              child: Text(_text('Retry', 'फिर कोशिश करें', 'আবার চেষ্টা করুন')),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                          ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: dogSelectionOrange,
                      ),
                    );
                  }

                  final dogs = snapshot.data?.docs ?? [];

                  if (dogs.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFF0E2D5),
                            ),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 64,
                                color: dogSelectionOrange,
                              ),
                              SizedBox(height: 16),
                              Text(
                                _text('No Dogs Added Yet', 'अभी कोई डॉग नहीं जोड़ा गया', 'এখনও কোনো কুকুর যোগ করা হয়নি'),
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: dogSelectionText,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                _text('Add your dog’s details before continuing with booking.', 'बुकिंग जारी रखने से पहले अपने डॉग की जानकारी जोड़ें।', 'বুকিং চালিয়ে যাওয়ার আগে আপনার কুকুরের তথ্য যোগ করুন.'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: dogSelectionMuted,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _isOpeningDogs ? null : _addDog,
                          style: FilledButton.styleFrom(
                            backgroundColor: dogSelectionOrange,
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: const Icon(Icons.add),
                          label: Text(
                            _isOpeningDogs ? _text('Opening...', 'खोल रहे हैं...', 'খোলা হচ্ছে...') : _text('Add Your Dog', 'अपना डॉग जोड़ें', 'আপনার কুকুর যোগ করুন'),
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        _text('Which dog is going for a walk?', 'किस डॉग को वॉक पर जाना है?', 'কোন কুকুরটি হাঁটতে যাবে?'),
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: dogSelectionText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        _text('Select one dog for this booking. You can choose another dog for a separate booking later.', 'इस बुकिंग के लिए एक डॉग चुनें। अलग बुकिंग में बाद में दूसरा डॉग चुन सकते हैं।', 'এই বুকিংয়ের জন্য একটি কুকুর বেছে নিন। পরে আলাদা বুকিংয়ে অন্য কুকুর বেছে নিতে পারবেন.'),
                        style: TextStyle(
                          color: dogSelectionMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ...dogs.map((document) {
                        final dog = document.data();
                        final dogId = document.id;
                        final selected = _selectedDogId == dogId;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedDogId = dogId;
                                _selectedDog = {
                                  ...dog,
                                  'dogId': dogId,
                                };
                              });
                            },
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFFFE9D6)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: selected
                                      ? dogSelectionOrange
                                      : const Color(0xFFF0E2D5),
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? dogSelectionOrange
                                          : dogSelectionBackground,
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                      size: 29,
                                      color: selected
                                          ? Colors.white
                                          : dogSelectionOrange,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _dogName(dog),
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: dogSelectionText,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          _dogBreed(dog),
                                          style: const TextStyle(
                                            color: dogSelectionMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_dogGender(dog)} · '
                                          '${_dogAge(dog)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: dogSelectionMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: selected
                                        ? dogSelectionOrange
                                        : dogSelectionMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      OutlinedButton.icon(
                        onPressed: _isOpeningDogs ? null : _addDog,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dogSelectionOrange,
                          side: const BorderSide(
                            color: dogSelectionOrange,
                          ),
                          minimumSize: const Size.fromHeight(48),
                        ),
                        icon: const Icon(Icons.add),
                        label: Text(_text('Add Another Dog', 'एक और डॉग जोड़ें', 'আরেকটি কুকুর যোগ করুন')),
                      ),
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF0E2D5)),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isContinuing ? null : _continue,
                  style: FilledButton.styleFrom(
                    backgroundColor: dogSelectionOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isContinuing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          _text('Continue to Pickup Address', 'पिकअप पते पर आगे बढ़ें', 'পিকআপ ঠিকানায় এগিয়ে যান'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
