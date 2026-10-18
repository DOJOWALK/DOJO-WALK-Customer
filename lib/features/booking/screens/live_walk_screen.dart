import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../app/app_language.dart';

class LiveWalkScreen extends StatelessWidget {
  const LiveWalkScreen({super.key, required this.bookingId});

  final String bookingId;

  static const Color _orange = Color(0xFFFF7900);
  static const Color _cream = Color(0xFFFFFAF5);
  static const Color _text = Color(0xFF202020);
  static const Color _muted = Color(0xFF777777);

  String _t(String en, String hi, String bn) {
    switch (appLocale.value.languageCode) {
      case 'hi':
        return hi;
      case 'bn':
        return bn;
      default:
        return en;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: _cream,
      appBar: AppBar(
        backgroundColor: _cream,
        foregroundColor: _text,
        elevation: 0,
        title: Text(_t('Live Walk', 'लाइव वॉक', 'লাইভ ওয়াক')),
      ),
      body: user == null
          ? _message(
              Icons.lock_outline_rounded,
              _t('Please sign in to view this walk.',
                  'इस वॉक को देखने के लिए लॉग इन करें।',
                  'এই ওয়াক দেখতে লগ ইন করুন।'),
            )
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(bookingId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _message(
                    Icons.cloud_off_rounded,
                    _t('Walk details could not be loaded.',
                        'वॉक की जानकारी लोड नहीं हो सकी।',
                        'ওয়াকের তথ্য লোড করা যায়নি।'),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: _orange),
                  );
                }

                final doc = snapshot.data!;
                final data = doc.data();
                if (!doc.exists ||
                    data == null ||
                    data['customerId']?.toString() != user.uid) {
                  return _message(
                    Icons.info_outline_rounded,
                    _t('This walk is not available for your account.',
                        'यह वॉक आपके अकाउंट के लिए उपलब्ध नहीं है।',
                        'এই ওয়াকটি আপনার অ্যাকাউন্টে উপলব্ধ নয়।'),
                  );
                }

                final status =
                    (data['status'] ?? '').toString().trim().toLowerCase();
                final isActive =
                    status == 'in_progress' || status == 'in progress';
                final pet = data['petDetails'] is Map
                    ? Map<String, dynamic>.from(data['petDetails'] as Map)
                    : <String, dynamic>{};
                final dogName = (pet['name'] ?? data['dogName'] ?? '')
                    .toString()
                    .trim();
                final walkerName =
                    (data['walkerName'] ?? '').toString().trim();

                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFF0DF), Colors.white, Color(0xFFFFE0BD)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFFC98F)),
                        boxShadow: [
                          BoxShadow(
                            color: _orange.withValues(alpha: 0.12),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFA64D), _orange],
                              ),
                              borderRadius: BorderRadius.circular(23),
                            ),
                            child: Icon(
                              isActive
                                  ? Icons.directions_walk_rounded
                                  : Icons.pets_rounded,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isActive
                                ? _t('YOUR DOG IS ON A WALK',
                                    'आपका डॉग वॉक पर है',
                                    'আপনার কুকুর ওয়াকে আছে')
                                : _t('WALK STATUS',
                                    'वॉक का स्टेटस',
                                    'ওয়াকের স্ট্যাটাস'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _text,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xFFE6F7ED)
                                  : const Color(0xFFFFF0E3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isActive) ...[
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF20A464),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 7),
                                ],
                                Text(
                                  status.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(
                                    color: isActive
                                        ? const Color(0xFF16834E)
                                        : _orange,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isActive
                                ? _t('We will show live location here when the walker GPS connection is available.',
                                    'वॉकर का GPS कनेक्शन उपलब्ध होने पर लाइव लोकेशन यहाँ दिखेगी।',
                                    'ওয়াকারের GPS সংযোগ উপলব্ধ হলে এখানে লাইভ লোকেশন দেখানো হবে।')
                                : _t('This booking is not currently marked as an active walk.',
                                    'इस बुकिंग में अभी वॉक चालू नहीं दिखाई गई है।',
                                    'এই বুকিংয়ে বর্তমানে ওয়াক চালু হিসেবে দেখানো হচ্ছে না।'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (dogName.isNotEmpty)
                      _detailTile(
                        Icons.pets_rounded,
                        _t('Your dog', 'आपका डॉग', 'আপনার কুকুর'),
                        dogName,
                      ),
                    if (walkerName.isNotEmpty)
                      _detailTile(
                        Icons.person_pin_circle_outlined,
                        _t('Walker', 'वॉकर', 'ওয়াকার'),
                        walkerName,
                      ),
                    _detailTile(
                      Icons.confirmation_number_outlined,
                      _t('Booking reference', 'बुकिंग नंबर', 'বুকিং রেফারেন্স'),
                      doc.id,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: Text(_t('Back to Home',
                          'होम पर वापस जाएँ', 'হোমে ফিরে যান')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _orange,
                        side: const BorderSide(color: _orange),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _message(IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _orange, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _text,
                fontSize: 15,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFE1C8)),
        boxShadow: [
          BoxShadow(
            color: _orange.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: _orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
