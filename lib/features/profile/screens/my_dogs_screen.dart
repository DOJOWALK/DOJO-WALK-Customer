import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';

const Color dogsOrange = DojoWalkTheme.primary;
const Color dogsBackground = DojoWalkTheme.background;
const Color dogsText = DojoWalkTheme.text;
const Color dogsMuted = DojoWalkTheme.mutedText;

String _dogTr(String en, String hi, String bn) {
  switch (appLocale.value.languageCode) {
    case 'hi':
      return hi;
    case 'bn':
      return bn;
    default:
      return en;
  }
}

const List<String> dogBreeds = [
  'Labrador Retriever',
  'Golden Retriever',
  'German Shepherd',
  'Beagle',
  'Pug',
  'Poodle',
  'Rottweiler',
  'Shih Tzu',
  'Dachshund',
  'Doberman',
  'Boxer',
  'Siberian Husky',
  'Indian Pariah / Indie',
  'Mixed Breed',
  'Other',
];

const List<String> dogAges = [
  'Under 1 year',
  '1 year',
  '2 years',
  '3 years',
  '4 years',
  '5 years',
  '6 years',
  '7 years',
  '8 years',
  '9 years',
  '10 years',
  '11 years',
  '12 years',
  '13 years',
  '14 years',
  '15+ years',
];

const List<String> dogSizes = [
  'Small',
  'Medium',
  'Large',
  'Extra Large',
];

const List<String> dogGenders = ['Male', 'Female'];

const List<String> dogBehaviours = [
  'Friendly',
  'Calm',
  'Active / Energetic',
  'Shy / Nervous',
  'Pulls on leash',
  'Reactive toward dogs',
  'Barks frequently',
  'Needs experienced walker',
];

const List<String> dogCareOptions = [
  'Senior dog',
  'Puppy',
  'Injury / Recovery',
  'Medication needed',
  'Feeding instructions',
  'Extra supervision',
];

String _dogOption(String value) {
  const translations = <String, List<String>>{
    'Labrador Retriever': [
      'Labrador Retriever',
      'लैब्राडोर रिट्रीवर',
      'ল্যাব্রাডর রিট্রিভার',
    ],
    'Golden Retriever': [
      'Golden Retriever',
      'गोल्डन रिट्रीवर',
      'গোল্ডেন রিট্রিভার',
    ],
    'German Shepherd': [
      'German Shepherd',
      'जर्मन शेफर्ड',
      'জার্মান শেফার্ড',
    ],
    'Beagle': ['Beagle', 'बीगल', 'বিগল'],
    'Pug': ['Pug', 'पग', 'পাগ'],
    'Poodle': ['Poodle', 'पूडल', 'পুডল'],
    'Rottweiler': ['Rottweiler', 'रॉटवाइलर', 'রটওয়েইলার'],
    'Shih Tzu': ['Shih Tzu', 'शिह त्ज़ु', 'শিহ তজু'],
    'Dachshund': ['Dachshund', 'डैशहंड', 'ড্যাশহান্ড'],
    'Doberman': ['Doberman', 'डोबरमैन', 'ডোবারম্যান'],
    'Boxer': ['Boxer', 'बॉक्सर', 'বক্সার'],
    'Siberian Husky': ['Siberian Husky', 'साइबेरियन हस्की', 'সাইবেরিয়ান হাস্কি'],
    'Indian Pariah / Indie': [
      'Indian Pariah / Indie',
      'इंडियन पैरायाह / इंडी',
      'ইন্ডিয়ান প্যারিয়া / ইন্ডি',
    ],
    'Mixed Breed': ['Mixed Breed', 'मिक्स्ड ब्रीड', 'মিশ্র জাত'],
    'Other': ['Other', 'अन्य', 'অন্যান্য'],
    'Under 1 year': ['Under 1 year', '1 साल से कम', '১ বছরের কম'],
    '1 year': ['1 year', '1 साल', '১ বছর'],
    '2 years': ['2 years', '2 साल', '২ বছর'],
    '3 years': ['3 years', '3 साल', '৩ বছর'],
    '4 years': ['4 years', '4 साल', '৪ বছর'],
    '5 years': ['5 years', '5 साल', '৫ বছর'],
    '6 years': ['6 years', '6 साल', '৬ বছর'],
    '7 years': ['7 years', '7 साल', '৭ বছর'],
    '8 years': ['8 years', '8 साल', '৮ বছর'],
    '9 years': ['9 years', '9 साल', '৯ বছর'],
    '10 years': ['10 years', '10 साल', '১০ বছর'],
    '11 years': ['11 years', '11 साल', '১১ বছর'],
    '12 years': ['12 years', '12 साल', '১২ বছর'],
    '13 years': ['13 years', '13 साल', '১৩ বছর'],
    '14 years': ['14 years', '14 साल', '১৪ বছর'],
    '15+ years': ['15+ years', '15+ साल', '১৫+ বছর'],
    'Small': ['Small', 'छोटा', 'ছোট'],
    'Medium': ['Medium', 'मध्यम', 'মাঝারি'],
    'Large': ['Large', 'बड़ा', 'বড়'],
    'Extra Large': ['Extra Large', 'बहुत बड़ा', 'অতি বড়'],
    'Male': ['Male', 'नर', 'পুরুষ'],
    'Female': ['Female', 'मादा', 'মহিলা'],
    'Friendly': ['Friendly', 'मिलनसार', 'বন্ধুসুলভ'],
    'Calm': ['Calm', 'शांत', 'শান্ত'],
    'Active / Energetic': [
      'Active / Energetic',
      'सक्रिय / ऊर्जावान',
      'সক্রিয় / উদ্যমী',
    ],
    'Shy / Nervous': [
      'Shy / Nervous',
      'शर्मीला / घबराने वाला',
      'লাজুক / ভীত',
    ],
    'Pulls on leash': [
      'Pulls on leash',
      'पट्टा खींचता है',
      'লিশ টানে',
    ],
    'Reactive toward dogs': [
      'Reactive toward dogs',
      'दूसरे कुत्तों पर प्रतिक्रिया देता है',
      'অন্য কুকুর দেখলে প্রতিক্রিয়া দেখায়',
    ],
    'Barks frequently': [
      'Barks frequently',
      'बार-बार भौंकता है',
      'বারবার ঘেউ ঘেউ করে',
    ],
    'Needs experienced walker': [
      'Needs experienced walker',
      'अनुभवी वॉकर की ज़रूरत है',
      'অভিজ্ঞ ওয়াকার প্রয়োজন',
    ],
    'Senior dog': ['Senior dog', 'बुज़ुर्ग कुत्ता', 'বয়স্ক কুকুর'],
    'Puppy': ['Puppy', 'पिल्ला', 'কুকুরছানা'],
    'Injury / Recovery': [
      'Injury / Recovery',
      'चोट / रिकवरी',
      'আঘাত / সুস্থ হওয়া',
    ],
    'Medication needed': [
      'Medication needed',
      'दवा की ज़रूरत',
      'ওষুধ প্রয়োজন',
    ],
    'Feeding instructions': [
      'Feeding instructions',
      'खाना खिलाने के निर्देश',
      'খাওয়ানোর নির্দেশনা',
    ],
    'Extra supervision': [
      'Extra supervision',
      'अतिरिक्त निगरानी',
      'অতিরিক্ত নজরদারি',
    ],
  };

  final options = translations[value];
  if (options == null) return value;

  switch (appLocale.value.languageCode) {
    case 'hi':
      return options[1];
    case 'bn':
      return options[2];
    default:
      return options[0];
  }
}

/// Minimal read model used by the My Dogs list and its isolated widget tests.
class DogListRecord {
  const DogListRecord({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class MyDogsScreen extends StatefulWidget {
  const MyDogsScreen({
    super.key,
    this.currentUserId,
    this.watchDogs,
  });

  /// Optional read seams; all production mutations continue using Firestore.
  final String? Function()? currentUserId;
  final Stream<List<DogListRecord>> Function(String uid)? watchDogs;

  @override
  State<MyDogsScreen> createState() => _MyDogsScreenState();
}

class _MyDogsScreenState extends State<MyDogsScreen> {
  int _retryAttempt = 0;

  String? get _currentUserId =>
      widget.currentUserId?.call() ?? FirebaseAuth.instance.currentUser?.uid;

  Stream<List<DogListRecord>> _watchDogs(String uid) {
    final injected = widget.watchDogs;
    if (injected != null) return injected(uid);
    return _pets(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => DogListRecord(id: doc.id, data: doc.data()),
              )
              .toList(growable: false),
        );
  }

  CollectionReference<Map<String, dynamic>> _pets(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('pets');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        final uid = _currentUserId;

        return Scaffold(
          backgroundColor: dogsBackground,
          appBar: AppBar(
            backgroundColor: dogsBackground,
            elevation: 0,
            iconTheme: const IconThemeData(color: dogsText),
            title: Text(
              _dogTr('My Dogs', 'मेरे कुत्ते', 'আমার কুকুর'),
              style: const TextStyle(
                color: dogsText,
                fontSize: 23,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          body: uid == null
              ? _emptyState(
                  icon: Icons.lock_outline_rounded,
                  title: _dogTr(
                    'Login Required',
                    'लॉगिन ज़रूरी है',
                    'লগইন করা প্রয়োজন',
                  ),
                  subtitle: _dogTr(
                    'Please log in to manage your dogs.',
                    'अपने कुत्तों को मैनेज करने के लिए लॉगिन करें।',
                    'আপনার কুকুর পরিচালনা করতে লগইন করুন।',
                  ),
                )
              : StreamBuilder<List<DogListRecord>>(
                  key: ValueKey<int>(_retryAttempt),
                  stream: _watchDogs(uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return _emptyState(
                        icon: Icons.cloud_off_rounded,
                        title: _dogTr(
                          'Unable to load dogs',
                          'कुत्तों की जानकारी नहीं खुल पाई',
                          'কুকুরের তথ্য লোড করা যায়নি',
                        ),
                        subtitle: _dogTr(
                          'Please check your connection and try again.',
                          'इंटरनेट कनेक्शन जाँचकर फिर कोशिश करें।',
                          'ইন্টারনেট সংযোগ পরীক্ষা করে আবার চেষ্টা করুন।',
                        ),
                        onRetry: () {
                          setState(() => _retryAttempt++);
                        },
                      );
                    }

                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: dogsOrange,
                        ),
                      );
                    }

                    final docs = snapshot.data ?? <DogListRecord>[];

                    if (docs.isEmpty) {
                      return _emptyState(
                        icon: Icons.pets_rounded,
                        title: _dogTr(
                          'No Dogs Added Yet',
                          'अभी कोई कुत्ता नहीं जोड़ा गया',
                          'এখনও কোনো কুকুর যোগ করা হয়নি',
                        ),
                        subtitle: _dogTr(
                          'Add your dog once and select it for future bookings.',
                          'अपने कुत्ते को एक बार जोड़ें और अगली बुकिंग में चुनें।',
                          'একবার আপনার কুকুর যোগ করুন এবং ভবিষ্যতের বুকিংয়ে বেছে নিন।',
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                      children: [
                        Text(
                          '${docs.length} ${docs.length == 1 ? _dogTr('Dog', 'कुत्ता', 'কুকুর') : _dogTr('Dogs', 'कुत्ते', 'কুকুর')}',
                          style: const TextStyle(
                            color: dogsMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...docs.map((doc) {
                          final data = doc.data;
                          final name =
                              (data['name'] ?? 'My Dog').toString();
                          final breed =
                              (data['breed'] ?? '').toString();
                          final age = (data['age'] ?? '').toString();
                          final size = (data['size'] ?? '').toString();
                          final gender =
                              (data['gender'] ?? '').toString();
                          final behaviour =
                              _stringList(data['behaviour']);
                          final specialCare =
                              _stringList(data['specialCare']);
                          final notes =
                              (data['notes'] ?? '').toString().trim();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        color: dogsOrange.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.pets_rounded,
                                        color: dogsOrange,
                                        size: 31,
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              color: dogsText,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            breed.isEmpty
                                                ? _dogTr(
                                                    'Breed not added',
                                                    'नस्ल नहीं जोड़ी गई',
                                                    'জাত যোগ করা হয়নি',
                                                  )
                                                : _dogOption(breed),
                                            style: const TextStyle(
                                              color: dogsMuted,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              if (age.isNotEmpty)
                                                _dogOption(age),
                                              if (size.isNotEmpty)
                                                _dogOption(size),
                                              if (gender.isNotEmpty)
                                                _dogOption(gender),
                                            ].join(' • '),
                                            style: const TextStyle(
                                              color: dogsMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          _openDogForm(
                                            context,
                                            _pets(uid),
                                            dogId: doc.id,
                                            existingData: data,
                                          );
                                        } else if (action == 'delete') {
                                          _deleteDog(
                                            context,
                                            _pets(uid),
                                            doc.id,
                                            name,
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Text(
                                            _dogTr(
                                              'Edit Details',
                                              'जानकारी बदलें',
                                              'বিবরণ সম্পাদনা',
                                            ),
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Text(
                                            _dogTr(
                                              'Delete Dog',
                                              'कुत्ता हटाएँ',
                                              'কুকুর মুছুন',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (behaviour.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Text(
                                    _dogTr(
                                      'Behaviour',
                                      'व्यवहार',
                                      'আচরণ',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: dogsText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: behaviour
                                        .map(
                                          (item) => _tag(_dogOption(item)),
                                        )
                                        .toList(),
                                  ),
                                ],
                                if (specialCare.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _dogTr(
                                      'Special Care',
                                      'विशेष देखभाल',
                                      'বিশেষ যত্ন',
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: dogsText,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 7,
                                    runSpacing: 7,
                                    children: specialCare
                                        .map(
                                          (item) => _tag(_dogOption(item)),
                                        )
                                        .toList(),
                                  ),
                                ],
                                if (notes.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_dogTr('Previous notes', 'पिछले नोट्स', 'আগের নোট')} : $notes',
                                    style: const TextStyle(
                                      color: dogsMuted,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
          floatingActionButton: user == null
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openDogForm(
                    context,
                    _pets(uid),
                  ),
                  backgroundColor: dogsOrange,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    _dogTr('Add Dog', 'कुत्ता जोड़ें', 'কুকুর যোগ করুন'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
        );
      },
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toSet()
          .toList();
    }
    return [];
  }

  static Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: dogsOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: dogsText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: dogsOrange),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w900,
                color: dogsText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: dogsMuted,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_dogTr('Retry', 'फिर कोशिश करें', 'আবার চেষ্টা করুন')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: dogsOrange,
                  side: const BorderSide(color: dogsOrange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openDogForm(
    BuildContext pageContext,
    CollectionReference<Map<String, dynamic>> collection, {
    String? dogId,
    Map<String, dynamic>? existingData,
  }) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: (existingData?['name'] ?? '').toString(),
    );

    String breed = (existingData?['breed'] ?? '').toString();
    String age = _normalizeAge(existingData?['age']);
    String size = (existingData?['size'] ?? 'Medium').toString();
    String gender = (existingData?['gender'] ?? 'Male').toString();

    final selectedBehaviour =
        _stringList(existingData?['behaviour']);
    final selectedCare = _stringList(existingData?['specialCare']);

    final breeds = [...dogBreeds];
    if (breed.isNotEmpty && !breeds.contains(breed)) {
      breeds.insert(0, breed);
    }
    if (!breeds.contains(breed)) breed = '';

    if (!dogAges.contains(age)) age = '';
    if (!dogSizes.contains(size)) size = 'Medium';
    if (!dogGenders.contains(gender)) gender = 'Male';

    bool saving = false;

    try {
      await showModalBottomSheet<void>(
        context: pageContext,
        isScrollControlled: true,
        backgroundColor: dogsBackground,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        builder: (sheetContext) {
          return ValueListenableBuilder<Locale>(
            valueListenable: appLocale,
            builder: (context, locale, child) {
              return StatefulBuilder(
                builder: (sheetContext, setSheetState) {
                  Future<void> saveDog() async {
                    if (saving) return;
                    if (!formKey.currentState!.validate()) return;

                    setSheetState(() => saving = true);

                    final data = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'breed': breed,
                      'age': age,
                      'size': size,
                      'gender': gender,
                      'behaviour': List<String>.from(selectedBehaviour),
                      'specialCare': List<String>.from(selectedCare),
                      'notes':
                          (existingData?['notes'] ?? '').toString(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    try {
                      if (dogId == null) {
                        data['createdAt'] = FieldValue.serverTimestamp();
                        await collection.add(data);
                      } else {
                        await collection.doc(dogId).update(data);
                      }

                      if (!pageContext.mounted) return;

                      Navigator.of(sheetContext).pop();

                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            dogId == null
                                ? _dogTr(
                                    'Dog added successfully.',
                                    'कुत्ता सफलतापूर्वक जोड़ दिया गया।',
                                    'কুকুর সফলভাবে যোগ করা হয়েছে।',
                                  )
                                : _dogTr(
                                    'Dog details updated.',
                                    'कुत्ते की जानकारी अपडेट हो गई।',
                                    'কুকুরের বিবরণ আপডেট হয়েছে।',
                                  ),
                          ),
                          backgroundColor: dogsOrange,
                        ),
                      );
                    } catch (error) {
                      setSheetState(() => saving = false);

                      ScaffoldMessenger.of(pageContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            _dogTr(
                              'Could not save dog details. Please try again.',
                              'कुत्ते की जानकारी सेव नहीं हुई। दोबारा कोशिश करें।',
                              'কুকুরের তথ্য সংরক্ষণ করা যায়নি। আবার চেষ্টা করুন।',
                            ),
                          ),
                        ),
                      );
                    }
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 22,
                      bottom:
                          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                    ),
                    child: Form(
                      key: formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              dogId == null
                                  ? _dogTr(
                                      'Add Your Dog',
                                      'अपने कुत्ते को जोड़ें',
                                      'আপনার কুকুর যোগ করুন',
                                    )
                                  : _dogTr(
                                      'Edit Dog Details',
                                      'कुत्ते की जानकारी बदलें',
                                      'কুকুরের বিবরণ সম্পাদনা করুন',
                                    ),
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                                color: dogsText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dogTr(
                                'Enter your dog’s details so the walker knows how to care for them.',
                                'अपने कुत्ते की जानकारी भरें, ताकि वॉकर उसकी सही देखभाल कर सके।',
                                'আপনার কুকুরের বিবরণ দিন, যাতে ওয়াকার সঠিকভাবে যত্ন নিতে পারেন।',
                              ),
                              style: const TextStyle(
                                color: dogsMuted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 22),

                            _label(_dogTr('Dog Name *', 'कुत्ते का नाम *', 'কুকুরের নাম *')),
                            TextFormField(
                              controller: nameController,
                              textCapitalization: TextCapitalization.words,
                              maxLength: 50,
                              decoration: _decoration(
                                _dogTr('e.g. Bruno', 'जैसे Bruno', 'যেমন Bruno'),
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return _dogTr(
                                    'Please enter your dog’s name',
                                    'कृपया कुत्ते का नाम भरें',
                                    'কুকুরের নাম লিখুন',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            _label(_dogTr('Breed *', 'नस्ल *', 'জাত *')),
                            DropdownButtonFormField<String>(
                              initialValue: breed.isEmpty ? null : breed,
                              isExpanded: true,
                              decoration: _decoration(
                                _dogTr('Select breed', 'नस्ल चुनें', 'জাত বেছে নিন'),
                              ),
                              items: breeds
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(_dogOption(item)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() => breed = value);
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? _dogTr(
                                          'Please select a breed',
                                          'कृपया नस्ल चुनें',
                                          'জাত বেছে নিন',
                                        )
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            _label(_dogTr('Age *', 'उम्र *', 'বয়স *')),
                            DropdownButtonFormField<String>(
                              initialValue: age.isEmpty ? null : age,
                              isExpanded: true,
                              decoration: _decoration(
                                _dogTr('Select age', 'उम्र चुनें', 'বয়স বেছে নিন'),
                              ),
                              items: dogAges
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(_dogOption(item)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() => age = value);
                                }
                              },
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? _dogTr(
                                          'Please select age',
                                          'कृपया उम्र चुनें',
                                          'বয়স বেছে নিন',
                                        )
                                      : null,
                            ),
                            const SizedBox(height: 14),

                            _label(_dogTr('Size *', 'आकार *', 'আকার *')),
                            DropdownButtonFormField<String>(
                              initialValue: size,
                              isExpanded: true,
                              decoration: _decoration(
                                _dogTr('Select size', 'आकार चुनें', 'আকার বেছে নিন'),
                              ),
                              items: dogSizes
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(_dogOption(item)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() => size = value);
                                }
                              },
                            ),
                            const SizedBox(height: 14),

                            _label(_dogTr('Gender *', 'लिंग *', 'লিঙ্গ *')),
                            DropdownButtonFormField<String>(
                              initialValue: gender,
                              isExpanded: true,
                              decoration: _decoration(
                                _dogTr('Select gender', 'लिंग चुनें', 'লিঙ্গ বেছে নিন'),
                              ),
                              items: dogGenders
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(_dogOption(item)),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setSheetState(() => gender = value);
                                }
                              },
                            ),
                            const SizedBox(height: 22),

                            _label(_dogTr('Behaviour *', 'व्यवहार *', 'আচরণ *')),
                            Text(
                              _dogTr(
                                'Select all that apply.',
                                'जो लागू हों, वे सभी चुनें।',
                                'যেগুলো প্রযোজ্য, সব বেছে নিন।',
                              ),
                              style: const TextStyle(
                                color: dogsMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...dogBehaviours.map(
                              (item) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: dogsOrange,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  _dogOption(item),
                                  style: const TextStyle(
                                    color: dogsText,
                                    fontSize: 14,
                                  ),
                                ),
                                value: selectedBehaviour.contains(item),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selectedBehaviour.add(item);
                                    } else {
                                      selectedBehaviour.remove(item);
                                    }
                                  });
                                },
                              ),
                            ),
                            if (selectedBehaviour.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  _dogTr(
                                    'Select at least one behaviour.',
                                    'कम से कम एक व्यवहार चुनें।',
                                    'অন্তত একটি আচরণ বেছে নিন।',
                                  ),
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 14),

                            _label(
                              _dogTr(
                                'Special Care (Optional)',
                                'विशेष देखभाल (वैकल्पिक)',
                                'বিশেষ যত্ন (ঐচ্ছিক)',
                              ),
                            ),
                            Text(
                              _dogTr(
                                'Select any care requirements.',
                                'देखभाल की ज़रूरतें चुनें।',
                                'যত্নের প্রয়োজনীয়তা বেছে নিন।',
                              ),
                              style: const TextStyle(
                                color: dogsMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...dogCareOptions.map(
                              (item) => CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                activeColor: dogsOrange,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                title: Text(
                                  _dogOption(item),
                                  style: const TextStyle(
                                    color: dogsText,
                                    fontSize: 14,
                                  ),
                                ),
                                value: selectedCare.contains(item),
                                onChanged: (checked) {
                                  setSheetState(() {
                                    if (checked == true) {
                                      selectedCare.add(item);
                                    } else {
                                      selectedCare.remove(item);
                                    }
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 18),

                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: saving
                                    ? null
                                    : () {
                                        if (selectedBehaviour.isEmpty) {
                                          ScaffoldMessenger.of(pageContext)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                _dogTr(
                                                  'Please select at least one behaviour.',
                                                  'कम से कम एक व्यवहार चुनें।',
                                                  'অন্তত একটি আচরণ বেছে নিন।',
                                                ),
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        saveDog();
                                      },
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
                                        dogId == null
                                            ? _dogTr(
                                                'Save Dog',
                                                'कुत्ता सेव करें',
                                                'কুকুর সংরক্ষণ করুন',
                                              )
                                            : _dogTr(
                                                'Update Dog',
                                                'जानकारी अपडेट करें',
                                                'কুকুরের তথ্য আপডেট করুন',
                                              ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
    }
  }

  String _normalizeAge(dynamic raw) {
    if (raw == null) return '';
    final value = raw.toString().trim();

    if (dogAges.contains(value)) return value;

    final number = int.tryParse(value);
    if (number == null) return '';

    if (number <= 0) return 'Under 1 year';
    if (number >= 15) return '15+ years';
    return '$number ${number == 1 ? 'year' : 'years'}';
  }

  Future<void> _deleteDog(
    BuildContext context,
    CollectionReference<Map<String, dynamic>> collection,
    String dogId,
    String dogName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _dogTr('Delete Dog?', 'कुत्ता हटाएँ?', 'কুকুর মুছবেন?'),
        ),
        content: Text(
          _dogTr(
            'Are you sure you want to delete $dogName from My Dogs?',
            'क्या आप $dogName को My Dogs से हटाना चाहते हैं?',
            'আপনি কি My Dogs থেকে $dogName-কে মুছে ফেলতে চান?',
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              _dogTr('Cancel', 'रद्द करें', 'বাতিল'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              _dogTr('Delete', 'हटाएँ', 'মুছুন'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      // Check the signed-in customer's booking history before deleting a dog.
      // Firestore rules allow customers to list only their own bookings.
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw StateError('Authentication is required to verify booking history.');
      }

      final bookingSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('customerId', isEqualTo: user.uid)
          .get();

      final hasBookingReference = bookingSnapshot.docs.any((booking) {
        final data = booking.data();
        final petDetails = data['petDetails'];
        final nestedDogId = petDetails is Map
            ? petDetails['dogId']?.toString()
            : null;
        return data['dogId']?.toString() == dogId ||
            nestedDogId == dogId;
      });

      if (!context.mounted) return;

      if (hasBookingReference) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _dogTr(
                'This dog is linked to booking history and cannot be deleted.',
                'यह कुत्ता बुकिंग हिस्ट्री से जुड़ा है, इसलिए इसे हटाया नहीं जा सकता।',
                'এই কুকুরটির বুকিং ইতিহাস রয়েছে, তাই এটি মুছে ফেলা যাবে না।',
              ),
            ),
          ),
        );
        return;
      }

      await collection.doc(dogId).delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _dogTr(
              'Dog deleted.',
              'कुत्ता हटा दिया गया।',
              'কুকুর মুছে ফেলা হয়েছে।',
            ),
          ),
          backgroundColor: dogsOrange,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _dogTr(
            'Could not delete dog. Please try again.',
            'कुत्ता हटाया नहीं जा सका। दोबारा कोशिश करें।',
            'কুকুর মুছে ফেলা যায়নি। আবার চেষ্টা করুন।',
          ),
          ),
        ),
      );
    }
  }

  static Widget _label(String text) {
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

  static InputDecoration _decoration(String hint) {
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
