
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color couponOrange = Color(0xFFFF7900);
const Color couponBackground = Color(0xFFFFFAF5);

class CouponsOffersScreen extends StatelessWidget {
  const CouponsOffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: couponBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF252525),
        elevation: 0,
        title: const Text(
          'Coupons & Offers',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('coupons')
              .where('isActive', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _MessageView(
                icon: Icons.cloud_off_outlined,
                title: 'Offers load nahi ho rahe',
                message:
                    'Internet connection aur Firebase permissions check karein.',
                onRetry: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CouponsOffersScreen(),
                    ),
                  );
                },
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: couponOrange),
              );
            }

            final now = Timestamp.now();

            final coupons = snapshot.data!.docs.where((doc) {
              final data = doc.data();
              final startAt = data['startAt'];
              final expiresAt = data['expiresAt'];

              if (startAt is! Timestamp || expiresAt is! Timestamp) {
                return false;
              }

              if (startAt.compareTo(now) > 0 ||
                  expiresAt.compareTo(now) <= 0) {
                return false;
              }

              final limit = data['usageLimit'];
              final redeemed = data['redeemedCount'] ?? 0;

              if (limit is num && redeemed is num && redeemed >= limit) {
                return false;
              }

              return true;
            }).toList();

            if (coupons.isEmpty) {
              return const _MessageView(
                icon: Icons.local_offer_outlined,
                title: 'Abhi koi offer nahi hai',
                message:
                    'Naye coupons aur special offers ke liye baad mein check karein.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [couponOrange, Color(0xFFFF9D45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.local_offer_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Save on your dog walks!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Choose an available offer and use it during booking.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Available Offers (${coupons.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF252525),
                  ),
                ),
                const SizedBox(height: 12),
                ...coupons.map((doc) {
                  return _CouponCard(
                    data: doc.data(),
                    documentId: doc.id,
                  );
                }),
                const SizedBox(height: 20),
                const Text(
                  'Offer availability and eligibility are checked when applying '
                  'a coupon to your booking.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CouponCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String documentId;

  const _CouponCard({
    required this.data,
    required this.documentId,
  });

  String get _discountText {
    final type = data['discountType'];
    final value = data['discountValue'];

    if (value is! num) return 'Special Offer';

    if (type == 'percentage') {
      return '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}% OFF';
    }

    if (type == 'fixed') {
      return '₹${value.toStringAsFixed(0)} OFF';
    }

    return 'Special Offer';
  }

  @override
  Widget build(BuildContext context) {
    final code = (data['code'] ?? documentId).toString();
    final description = (data['description'] ?? '').toString();
    final minAmount = data['minBookingAmount'];
    final expiresAt = data['expiresAt'];

    String expiryText = 'Check offer validity';

    if (expiresAt is Timestamp) {
      final date = expiresAt.toDate();
      expiryText =
          'Valid until ${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFDFC3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  color: couponOrange,
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _discountText,
                      style: const TextStyle(
                        color: couponOrange,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: couponBackground,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFFC48E),
                style: BorderStyle.solid,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 16,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: code));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Coupon code copied'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, size: 17),
                  label: const Text('Copy'),
                  style: TextButton.styleFrom(
                    foregroundColor: couponOrange,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (minAmount is num)
            Text(
              'Minimum booking amount: ₹${minAmount.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            expiryText,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Icon(
                Icons.info_outline,
                color: couponOrange,
                size: 16,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Apply this code during booking to check eligibility.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 58, color: couponOrange),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: couponOrange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
