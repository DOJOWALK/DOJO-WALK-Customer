import 'package:flutter/material.dart';

import '../../../app/locale_controller.dart';
import '../../../app/theme.dart';

const Color supportOrange = DojoWalkTheme.primary;
const Color supportBackground = DojoWalkTheme.background;
const Color supportText = DojoWalkTheme.text;
const Color supportMuted = DojoWalkTheme.mutedText;

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _category = 'Booking';

  String _tr(String en, String hi, String bn) {
    switch (appLocale.value.languageCode) {
      case 'hi':
        return hi;
      case 'bn':
        return bn;
      default:
        return en;
    }
  }

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do I book a dog walk?',
      'answer': 'Open Home, tap Book a Walk, choose your walk type, select your dog, add the pickup address and choose your schedule.',
    },
    {
      'question': 'What is a Regular Walk plan?',
      'answer': 'A Regular Walk plan is for continuing walks at your preferred time. Your final schedule and walker assignment should be confirmed by DOJO WALK.',
    },
    {
      'question': 'How can I manage my dog details?',
      'answer': 'Open My Dogs to add a dog, update saved details or delete a dog you no longer need in your list.',
    },
    {
      'question': 'Can I cancel a booking?',
      'answer': 'Open My Bookings and check the booking details for the available cancellation or cancellation-request option.',
    },
    {
      'question': 'What if my assigned walker is unavailable?',
      'answer': 'Contact support with your booking details so the team can review the situation and advise you about next steps.',
    },
    {
      'question': 'When is payment required?',
      'answer': 'Check the payment details shown during your booking. Do not assume a booking is paid until the app confirms the payment status.',
    },
  ];

  String _faqQuestion(String value) => switch (value) {
        'How do I book a dog walk?' => _tr('How do I book a dog walk?', 'डॉग वॉक कैसे बुक करें?', 'কুকুরের ওয়াক কীভাবে বুক করব?'),
        'What is a Regular Walk plan?' => _tr('What is a Regular Walk plan?', 'रेगुलर वॉक प्लान क्या है?', 'রেগুলার ওয়াক প্ল্যান কী?'),
        'How can I manage my dog details?' => _tr('How can I manage my dog details?', 'अपने कुत्ते की जानकारी कैसे संभालें?', 'কুকুরের তথ্য কীভাবে পরিচালনা করব?'),
        'Can I cancel a booking?' => _tr('Can I cancel a booking?', 'क्या बुकिंग रद्द कर सकता हूँ?', 'আমি কি বুকিং বাতিল করতে পারি?'),
        'What if my assigned walker is unavailable?' => _tr('What if my assigned walker is unavailable?', 'अगर असाइन किया गया वॉकर उपलब्ध न हो तो?', 'নির্ধারিত ওয়াকার না থাকলে কী হবে?'),
        _ => _tr('When is payment required?', 'भुगतान कब करना होगा?', 'কখন পেমেন্ট করতে হবে?'),
      };

  String _faqAnswer(String value) => switch (value) {
        'How do I book a dog walk?' => _tr(
            'Open Home, tap Book a Walk, choose your walk type, select your dog, add the pickup address and choose your schedule.',
            'होम खोलें, “वॉक बुक करें” चुनें, वॉक का प्रकार और अपना कुत्ता चुनें, पिकअप पता जोड़ें और समय तय करें।',
            'হোম খুলুন, “ওয়াক বুক করুন” চাপুন, ওয়াকের ধরন ও কুকুর বেছে নিন, পিকআপ ঠিকানা যোগ করুন এবং সময় নির্বাচন করুন।'),
        'What is a Regular Walk plan?' => _tr(
            'A Regular Walk plan is for continuing walks at your preferred time. Your final schedule and walker assignment should be confirmed by DOJO WALK.',
            'रेगुलर वॉक प्लान पसंदीदा समय पर नियमित वॉक के लिए है। अंतिम शेड्यूल और वॉकर की पुष्टि DOJO WALK करेगा।',
            'রেগুলার ওয়াক প্ল্যান পছন্দের সময়ে নিয়মিত ওয়াকের জন্য। চূড়ান্ত সময়সূচি ও ওয়াকার DOJO WALK নিশ্চিত করবে।'),
        'How can I manage my dog details?' => _tr(
            'Open My Dogs to add a dog, update saved details or delete a dog you no longer need in your list.',
            'कुत्ता जोड़ने, जानकारी बदलने या सूची से हटाने के लिए “मेरे कुत्ते” खोलें।',
            'কুকুর যোগ, তথ্য পরিবর্তন বা তালিকা থেকে মুছতে “আমার কুকুর” খুলুন।'),
        'Can I cancel a booking?' => _tr(
            'Open My Bookings and check the booking details for the available cancellation or cancellation-request option.',
            '“मेरी बुकिंग” खोलें और बुकिंग विवरण में उपलब्ध रद्द करने या अनुरोध करने का विकल्प देखें।',
            '“আমার বুকিং” খুলে বুকিংয়ের বিবরণে বাতিল বা বাতিলের অনুরোধের বিকল্প দেখুন।'),
        'What if my assigned walker is unavailable?' => _tr(
            'Contact support with your booking details so the team can review the situation and advise you about next steps.',
            'बुकिंग विवरण के साथ सपोर्ट से संपर्क करें, ताकि टीम स्थिति देखकर अगले कदम बता सके।',
            'বুকিংয়ের বিবরণসহ সাপোর্টে যোগাযোগ করুন, যাতে দলটি পরিস্থিতি দেখে পরবর্তী পদক্ষেপ জানাতে পারে।'),
        _ => _tr(
            'Check the payment details shown during your booking. Do not assume a booking is paid until the app confirms the payment status.',
            'बुकिंग के दौरान दिखाए गए भुगतान विवरण देखें। ऐप द्वारा भुगतान की पुष्टि होने से पहले बुकिंग को भुगतान किया हुआ न मानें।',
            'বুকিংয়ের সময় দেখানো পেমেন্টের বিবরণ দেখুন। অ্যাপে নিশ্চিত না হওয়া পর্যন্ত বুকিংকে পেমেন্ট করা হয়েছে বলে ধরে নেবেন না।'),
      };

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_tr(
            'Your message is not sent yet. Support submission will be enabled after integration.',
            'आपका संदेश अभी भेजा नहीं गया है। इंटीग्रेशन के बाद सपोर्ट अनुरोध भेजना उपलब्ध होगा।',
            'আপনার বার্তাটি এখনও পাঠানো হয়নি। ইন্টিগ্রেশনের পরে সাপোর্ট অনুরোধ পাঠানো যাবে।',
          )),
          backgroundColor: supportOrange,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        return Scaffold(
          backgroundColor: supportBackground,
          appBar: AppBar(
            backgroundColor: supportBackground,
            foregroundColor: supportText,
            elevation: 0,
            title: Text(
              _tr('Help & Support', 'मदद और सहायता', 'সহায়তা ও সাপোর্ট'),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 21),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: supportOrange,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: Colors.white, size: 43),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_tr('How can we help?', 'हम आपकी कैसे मदद करें?', 'আমরা কীভাবে সাহায্য করতে পারি?'),
                              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(_tr(
                            'Find answers about your dog walks and bookings.',
                            'डॉग वॉक और बुकिंग से जुड़े जवाब यहाँ पाएँ।',
                            'ডগ ওয়াক ও বুকিং সম্পর্কে উত্তর এখানে খুঁজুন।',
                          ), style: const TextStyle(color: Colors.white, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(_tr('Frequently Asked Questions', 'अक्सर पूछे जाने वाले सवाल', 'প্রায়শই জিজ্ঞাসিত প্রশ্ন'),
                  style: const TextStyle(color: supportText, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _faqs.length; i++) ...[
                      ExpansionTile(
                        key: PageStorageKey<String>(_faqs[i]['question']!),
                        tilePadding: const EdgeInsets.symmetric(horizontal: 15),
                        childrenPadding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                        iconColor: supportOrange,
                        collapsedIconColor: supportMuted,
                        title: Text(_faqQuestion(_faqs[i]['question']!),
                            style: const TextStyle(color: supportText, fontWeight: FontWeight.w700, fontSize: 14)),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_faqAnswer(_faqs[i]['question']!),
                                style: const TextStyle(color: supportMuted, height: 1.5, fontSize: 13)),
                          ),
                        ],
                      ),
                      if (i != _faqs.length - 1) const Divider(height: 1, indent: 15, endIndent: 15),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(_tr('Still need help?', 'अब भी मदद चाहिए?', 'এখনও সাহায্য দরকার?'),
                  style: const TextStyle(color: supportText, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(_tr('Describe your issue below.', 'अपनी समस्या नीचे लिखें।', 'নিচে আপনার সমস্যাটি লিখুন।'),
                  style: const TextStyle(color: supportMuted, height: 1.4)),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEEEEEE)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_tr('What do you need help with?', 'किस विषय में मदद चाहिए?', 'কোন বিষয়ে সাহায্য দরকার?'),
                          style: const TextStyle(color: supportText, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: _inputDecoration(_tr('Select a topic', 'विषय चुनें', 'বিষয় বেছে নিন')),
                        items: [
                          DropdownMenuItem(value: 'Booking', child: Text(_tr('Booking', 'बुकिंग', 'বুকিং'))),
                          DropdownMenuItem(value: 'Regular Walk Plan', child: Text(_tr('Regular Walk Plan', 'रेगुलर वॉक प्लान', 'রেগুলার ওয়াক প্ল্যান'))),
                          DropdownMenuItem(value: 'Walker', child: Text(_tr('Walker', 'वॉकर', 'ওয়াকার'))),
                          DropdownMenuItem(value: 'Payment', child: Text(_tr('Payment', 'भुगतान', 'পেমেন্ট'))),
                          DropdownMenuItem(value: 'My Dogs', child: Text(_tr('My Dogs', 'मेरे कुत्ते', 'আমার কুকুর'))),
                          DropdownMenuItem(value: 'Safety', child: Text(_tr('Safety', 'सुरक्षा', 'নিরাপত্তা'))),
                          DropdownMenuItem(value: 'Other', child: Text(_tr('Other', 'अन्य', 'অন্যান্য'))),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(_tr('Describe your issue', 'अपनी समस्या बताएँ', 'আপনার সমস্যা বর্ণনা করুন'),
                          style: const TextStyle(color: supportText, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(_tr('Tell us what happened...', 'क्या हुआ, हमें बताएँ...', 'কী ঘটেছে আমাদের জানান...')),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return _tr('Please enter at least 10 characters.', 'कृपया कम से कम 10 अक्षर लिखें।', 'কমপক্ষে ১০টি অক্ষর লিখুন।');
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _submitRequest,
                          icon: const Icon(Icons.send_rounded),
                          label: Text(_tr('Submit Support Request', 'सपोर्ट अनुरोध भेजें', 'সাপোর্ট অনুরোধ জমা দিন'),
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: supportOrange,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(_tr(
                        'Not connected yet: this form will not send your message until support integration is implemented.',
                        'अभी कनेक्ट नहीं है: सपोर्ट इंटीग्रेशन होने तक यह फ़ॉर्म आपका संदेश नहीं भेजेगा।',
                        'এখনও সংযুক্ত নয়: সাপোর্ট ইন্টিগ্রেশন না হওয়া পর্যন্ত এই ফর্ম বার্তা পাঠাবে না।',
                      ), style: const TextStyle(color: supportMuted, fontSize: 12, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: supportBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: supportOrange, width: 1.5)),
    );
  }
}
