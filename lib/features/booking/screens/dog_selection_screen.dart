import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../profile/screens/my_dogs_screen.dart';
import 'choose_walk_screen.dart';
import 'pickup_address_selection_screen.dart';
import '../../../app/theme.dart';
import '../../../app/locale_controller.dart';
import '../../../l10n/app_localizations.dart';

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

  String _dogBreed(BuildContext context, Map<String, dynamic> dog) {
    final breed = (dog['breed'] ?? '').toString().trim();
    return breed.isEmpty ? AppLocalizations.of(context).dogBreedNotProvided : breed;
  }

  String _dogGender(BuildContext context, Map<String, dynamic> dog) {
    final gender = (dog['gender'] ?? '').toString().trim();
    return gender.isEmpty ? AppLocalizations.of(context).dogNotSpecified : gender;
  }

  String _dogAge(BuildContext context, Map<String, dynamic> dog) {
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
        return '$years ${AppLocalizations.of(context).dogAgeYears}';
      }
    }

    return AppLocalizations.of(context).dogAgeNotProvided;
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
      _showMessage(AppLocalizations.of(context).dogOpenDetailsFailed);
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
      _showMessage(AppLocalizations.of(context).dogLoginFirst);
      return;
    }

    final dogId = _selectedDogId;
    final selectedDog = _selectedDog;

    if (dogId == null || selectedDog == null) {
      _showMessage(AppLocalizations.of(context).dogSelectOne);
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
          AppLocalizations.of(context).dogNoLongerSaved,
        );
      }

      final savedDog = dogDocument.data() ?? <String, dynamic>{};

      final name = _dogName(savedDog);

      if (name.isEmpty || name == 'Unnamed Dog') {
        throw StateError(
          AppLocalizations.of(context).dogNameMissing,
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
            ? AppLocalizations.of(context).dogAccessFailed
            : AppLocalizations.of(context).dogLoadFailed,
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
          title: Text(AppLocalizations.of(context).dogSelectionTitle),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              AppLocalizations.of(context).dogLoginToSelect,
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
          AppLocalizations.of(context).dogSelectionTitle,
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
                            Text(
                              AppLocalizations.of(context).dogLoadFailed,
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
                              child: Text(AppLocalizations.of(context).dogSelectionRetry),
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
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets,
                                size: 64,
                                color: dogSelectionOrange,
                              ),
                              SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context).dogSelectionEmptyTitle,
                                style: TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: dogSelectionText,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                AppLocalizations.of(context).dogSelectionEmptyBody,
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
                            _isOpeningDogs ? AppLocalizations.of(context).dogSelectionOpening : AppLocalizations.of(context).dogSelectionAddDog,
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        AppLocalizations.of(context).dogWhichForWalk,
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: dogSelectionText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        AppLocalizations.of(context).dogOnePerBooking,
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
                                          _dogBreed(context, dog),
                                          style: const TextStyle(
                                            color: dogSelectionMuted,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_dogGender(context, dog)} · '
                                          '${_dogAge(context, dog)}',
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
                        label: Text(AppLocalizations.of(context).dogAddAnother),
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
                      : Text(
                          AppLocalizations.of(context).dogContinuePickup,
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
