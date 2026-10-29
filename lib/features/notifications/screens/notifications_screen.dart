import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  String _text(String en, String hi, String bn, Locale locale) {
    switch (locale.languageCode) {
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
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: DojoWalkTheme.background,
          appBar: AppBar(
            backgroundColor: DojoWalkTheme.background,
            foregroundColor: DojoWalkTheme.text,
            elevation: 0,
            title: Text(
              _text('Notifications', 'नोटिफ़िकेशन', 'বিজ্ঞপ্তি', locale),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: DojoWalkTheme.primary.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notifications_none_rounded,
                      size: 48,
                      color: DojoWalkTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _text(
                      'No notifications yet',
                      'अभी कोई नोटिफ़िकेशन नहीं है',
                      'এখনও কোনো বিজ্ঞপ্তি নেই',
                      locale,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: DojoWalkTheme.text,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _text(
                      'Booking updates, walk reminders and important messages will appear here when notifications are connected.',
                      'नोटिफ़िकेशन सेवा जुड़ने के बाद बुकिंग अपडेट, वॉक रिमाइंडर और ज़रूरी संदेश यहाँ दिखेंगे।',
                      'বিজ্ঞপ্তি পরিষেবা যুক্ত হলে বুকিং আপডেট, ওয়াকের রিমাইন্ডার এবং গুরুত্বপূর্ণ বার্তা এখানে দেখা যাবে।',
                      locale,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: DojoWalkTheme.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
