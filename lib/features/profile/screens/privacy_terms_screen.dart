import 'package:flutter/material.dart';
import '../../../app/app_language.dart';

const Color _orange = Color(0xFFFF7900);
const Color _background = Color(0xFFFFFAF5);
const Color _textColor = Color(0xFF292929);
const Color _mutedColor = Color(0xFF777777);

class PrivacyTermsScreen extends StatelessWidget {
  const PrivacyTermsScreen({super.key});

  String _tr(String en, String hi, String bn, String lang) {
    if (lang == 'hi') return hi;
    if (lang == 'bn') return bn;
    return en;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocale,
      builder: (context, locale, child) {
        final lang = locale.languageCode;

        return Scaffold(
          backgroundColor: _background,
          appBar: AppBar(
            backgroundColor: _background,
            foregroundColor: _textColor,
            elevation: 0,
            title: Text(
              _tr(
                'Privacy & Terms',
                'प्राइवेसी और नियम',
                'গোপনীয়তা ও শর্তাবলি',
                lang,
              ),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _orange.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: _orange,
                        size: 30,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tr(
                        'Your Trust Matters',
                        'आपका भरोसा हमारे लिए महत्वपूर्ण है',
                        'আপনার বিশ্বাস আমাদের কাছে গুরুত্বপূর্ণ',
                        lang,
                      ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tr(
                        'Learn how DOJO WALK handles your information and the rules that apply when you use our dog-walking services.',
                        'जानें कि DOJO WALK आपकी जानकारी का उपयोग कैसे करता है और हमारी डॉग-वॉकिंग सेवाओं के कौन-से नियम लागू होते हैं।',
                        'জানুন DOJO WALK কীভাবে আপনার তথ্য ব্যবহার করে এবং আমাদের ডগ-ওয়াকিং পরিষেবার কোন নিয়মগুলি প্রযোজ্য।',
                        lang,
                      ),
                      style: const TextStyle(
                        color: _mutedColor,
                        height: 1.6,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _heading(
                _tr(
                  'Privacy Policy',
                  'गोपनीयता नीति',
                  'গোপনীয়তা নীতি',
                  lang,
                ),
                Icons.privacy_tip_outlined,
              ),

              _section(
                _tr(
                  '1. Information We Collect',
                  '1. हम कौन-सी जानकारी लेते हैं',
                  '১. আমরা কোন তথ্য সংগ্রহ করি',
                  lang,
                ),
                _tr(
                  'Depending on the features you use, DOJO WALK may collect your name, phone number, account details, saved addresses, dog profile details, booking information and support messages.',
                  'आपके इस्तेमाल किए गए फीचर्स के अनुसार DOJO WALK आपका नाम, फोन नंबर, अकाउंट विवरण, सेव किए गए पते, डॉग की जानकारी, बुकिंग विवरण और सहायता संदेश एकत्र कर सकता है।',
                  'আপনার ব্যবহৃত ফিচার অনুযায়ী DOJO WALK আপনার নাম, ফোন নম্বর, অ্যাকাউন্টের বিবরণ, সংরক্ষিত ঠিকানা, কুকুরের তথ্য, বুকিংয়ের বিবরণ এবং সহায়তার বার্তা সংগ্রহ করতে পারে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '2. How We Use Your Information',
                  '2. आपकी जानकारी का उपयोग',
                  '২. আপনার তথ্যের ব্যবহার',
                  lang,
                ),
                _tr(
                  'Information may be used to create and manage your account, arrange dog walks, communicate booking updates, provide customer support, protect users and improve our services.',
                  'जानकारी का उपयोग आपका अकाउंट बनाने और मैनेज करने, डॉग वॉक की व्यवस्था करने, बुकिंग अपडेट देने, सहायता प्रदान करने, सुरक्षा बनाए रखने और सेवाओं में सुधार करने के लिए किया जा सकता है।',
                  'আপনার অ্যাকাউন্ট তৈরি ও পরিচালনা, ডগ ওয়াকের ব্যবস্থা, বুকিং আপডেট, গ্রাহক সহায়তা, নিরাপত্তা এবং পরিষেবার উন্নতির জন্য তথ্য ব্যবহার করা হতে পারে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '3. Location Information',
                  '3. लोकेशन की जानकारी',
                  '৩. অবস্থানের তথ্য',
                  lang,
                ),
                _tr(
                  'Location access may be needed for pickup addresses, service-area checks or walk-related features. Location access should be requested through your device permissions. You can manage permissions in your phone settings.',
                  'पिकअप पते, सेवा क्षेत्र की जाँच या वॉक से जुड़े फीचर्स के लिए लोकेशन की अनुमति आवश्यक हो सकती है। अनुमति आपके फोन के माध्यम से माँगी जाएगी और आप इसे फोन की सेटिंग्स में मैनेज कर सकते हैं।',
                  'পিকআপের ঠিকানা, পরিষেবা এলাকা যাচাই বা ওয়াক-সম্পর্কিত ফিচারের জন্য অবস্থানের অনুমতি প্রয়োজন হতে পারে। আপনি ফোনের সেটিংস থেকে এই অনুমতি পরিচালনা করতে পারবেন।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '4. Sharing Information',
                  '4. जानकारी साझा करना',
                  '৪. তথ্য শেয়ার করা',
                  lang,
                ),
                _tr(
                  'Relevant booking information may be shared with the assigned walker and authorized operations staff when necessary to provide the service. Information may also be processed by service providers that support the app. We do not promise that information is never shared; any sharing must follow applicable law and our actual service practices.',
                  'सेवा देने के लिए आवश्यक बुकिंग जानकारी संबंधित वॉकर और अधिकृत टीम के साथ साझा की जा सकती है। ऐप चलाने वाले सेवा प्रदाता भी जानकारी प्रोसेस कर सकते हैं। हम यह दावा नहीं करते कि जानकारी कभी साझा नहीं होती; सभी प्रक्रियाएँ लागू कानून और वास्तविक सेवा व्यवस्था के अनुसार होनी चाहिए।',
                  'পরিষেবা দেওয়ার জন্য প্রয়োজনীয় বুকিংয়ের তথ্য নির্ধারিত ওয়াকার এবং অনুমোদিত কর্মীদের সঙ্গে শেয়ার করা হতে পারে। অ্যাপ পরিচালনাকারী পরিষেবা প্রদানকারীরাও তথ্য প্রক্রিয়া করতে পারেন। তথ্য শেয়ারিং প্রযোজ্য আইন ও বাস্তব পরিষেবা ব্যবস্থার সঙ্গে সামঞ্জস্যপূর্ণ হতে হবে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '5. Data Security and Retention',
                  '5. डेटा सुरक्षा और संग्रह',
                  '৫. তথ্যের নিরাপত্তা ও সংরক্ষণ',
                  lang,
                ),
                _tr(
                  'We aim to use reasonable safeguards to protect information. No online system can guarantee absolute security. Information should be retained only as needed for service delivery, legal obligations and legitimate business purposes.',
                  'हम जानकारी की सुरक्षा के लिए उचित उपाय अपनाने का प्रयास करते हैं। कोई भी ऑनलाइन सिस्टम पूरी सुरक्षा की गारंटी नहीं दे सकता। जानकारी को सेवा, कानूनी दायित्वों और वैध व्यावसायिक जरूरतों के अनुसार ही रखा जाना चाहिए।',
                  'তথ্য সুরক্ষার জন্য যুক্তিসঙ্গত ব্যবস্থা নেওয়ার চেষ্টা করা হয়। কোনো অনলাইন ব্যবস্থাই সম্পূর্ণ নিরাপত্তার নিশ্চয়তা দিতে পারে না। পরিষেবা, আইনি দায়িত্ব এবং বৈধ ব্যবসায়িক প্রয়োজন অনুযায়ী তথ্য সংরক্ষণ করা উচিত।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '6. Your Information and Requests',
                  '6. आपकी जानकारी और अनुरोध',
                  '৬. আপনার তথ্য ও অনুরোধ',
                  lang,
                ),
                _tr(
                  'You can contact DOJO WALK to ask about your personal information, request corrections or raise a privacy concern. Requests may be subject to identity verification and applicable legal requirements.',
                  'आप अपनी व्यक्तिगत जानकारी के बारे में पूछने, उसमें सुधार कराने या गोपनीयता संबंधी शिकायत दर्ज करने के लिए DOJO WALK से संपर्क कर सकते हैं। अनुरोध के लिए पहचान की पुष्टि और कानूनी आवश्यकताएँ लागू हो सकती हैं।',
                  'আপনার ব্যক্তিগত তথ্য সম্পর্কে জানতে, সংশোধনের অনুরোধ করতে বা গোপনীয়তার অভিযোগ জানাতে DOJO WALK-এর সঙ্গে যোগাযোগ করতে পারেন। পরিচয় যাচাই এবং প্রযোজ্য আইনি শর্ত পূরণ করতে হতে পারে।',
                  lang,
                ),
              ),

              const SizedBox(height: 20),

              _heading(
                _tr(
                  'Terms & Conditions',
                  'नियम और शर्तें',
                  'নিয়ম ও শর্তাবলি',
                  lang,
                ),
                Icons.description_outlined,
              ),

              _section(
                _tr(
                  '1. Using DOJO WALK',
                  '1. DOJO WALK का उपयोग',
                  '১. DOJO WALK ব্যবহার',
                  lang,
                ),
                _tr(
                  'By using the service, you agree to provide accurate booking and contact details and to follow the applicable service rules. You must be authorized to arrange walks for the dog you register.',
                  'सेवा का उपयोग करके आप सही बुकिंग और संपर्क विवरण देने तथा लागू नियमों का पालन करने के लिए सहमत होते हैं। जिस डॉग की वॉक बुक करते हैं, उसके लिए आपके पास आवश्यक अनुमति होनी चाहिए।',
                  'পরিষেবা ব্যবহার করে আপনি সঠিক বুকিং ও যোগাযোগের তথ্য দিতে এবং প্রযোজ্য নিয়ম মানতে সম্মত হন। যে কুকুরের ওয়াক বুক করছেন, তার জন্য আপনার অনুমতি থাকা প্রয়োজন।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '2. One-Time and Regular Walks',
                  '2. वन-टाइम और रेगुलर वॉक',
                  '২. একবারের ও নিয়মিত ওয়াক',
                  lang,
                ),
                _tr(
                  'A one-time walk is a single booking. A regular plan is intended for recurring walks according to the agreed schedule and plan details. Requested times are subject to confirmation and walker availability.',
                  'वन-टाइम वॉक एक बार की बुकिंग है। रेगुलर प्लान तय शेड्यूल और प्लान के अनुसार बार-बार होने वाली वॉक के लिए है। माँगा गया समय पुष्टि और वॉकर की उपलब्धता पर निर्भर करेगा।',
                  'একবারের ওয়াক একটি বুকিং। নিয়মিত প্ল্যান নির্ধারিত সময়সূচি অনুযায়ী পুনরাবৃত্ত ওয়াকের জন্য। অনুরোধ করা সময় নিশ্চিতকরণ ও ওয়াকারের প্রাপ্যতার উপর নির্ভর করবে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '3. Dog Safety and Customer Responsibilities',
                  '3. डॉग की सुरक्षा और ग्राहक की जिम्मेदारी',
                  '৩. কুকুরের নিরাপত্তা ও গ্রাহকের দায়িত্ব',
                  lang,
                ),
                _tr(
                  'Provide accurate information about your dog, including behaviour, health-related needs, handling requirements and any known safety concerns. Ensure the dog can be safely handed over and collected. Inform the team about important changes before a walk.',
                  'अपने डॉग के व्यवहार, स्वास्थ्य संबंधी जरूरतों, संभालने के तरीके और सुरक्षा संबंधी जानकारी सही दें। सुनिश्चित करें कि डॉग को सुरक्षित रूप से सौंपा और वापस लिया जा सके। वॉक से पहले जरूरी बदलाव टीम को बताएँ।',
                  'কুকুরের আচরণ, স্বাস্থ্যসংক্রান্ত প্রয়োজন, সামলানোর নির্দেশনা এবং নিরাপত্তার ঝুঁকি সম্পর্কে সঠিক তথ্য দিন। কুকুরকে নিরাপদে হস্তান্তর ও ফিরিয়ে নেওয়ার ব্যবস্থা করুন। ওয়াকের আগে গুরুত্বপূর্ণ পরিবর্তন জানান।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '4. Walker Assignment and Availability',
                  '4. वॉकर असाइनमेंट और उपलब्धता',
                  '৪. ওয়াকার নিয়োগ ও প্রাপ্যতা',
                  lang,
                ),
                _tr(
                  'DOJO WALK will communicate assignment and booking status through the available service channels. A preferred walker or requested time cannot be guaranteed unless expressly confirmed. If a walker becomes unavailable, the team may contact you about an alternative arrangement.',
                  'DOJO WALK उपलब्ध माध्यमों से वॉकर और बुकिंग की स्थिति बताएगा। स्पष्ट पुष्टि के बिना पसंदीदा वॉकर या समय की गारंटी नहीं है। वॉकर उपलब्ध न होने पर टीम वैकल्पिक व्यवस्था के लिए आपसे संपर्क कर सकती है।',
                  'DOJO WALK উপলব্ধ মাধ্যমের মাধ্যমে ওয়াকার ও বুকিংয়ের অবস্থা জানাবে। স্পষ্ট নিশ্চিতকরণ ছাড়া পছন্দের ওয়াকার বা সময়ের নিশ্চয়তা নেই। ওয়াকার অনুপলব্ধ হলে বিকল্প ব্যবস্থা নিয়ে যোগাযোগ করা হতে পারে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '5. Pricing, Cancellation and Refunds',
                  '5. कीमत, कैंसलेशन और रिफंड',
                  '৫. মূল্য, বাতিল ও রিফান্ড',
                  lang,
                ),
                _tr(
                  'Applicable prices and plan details should be shown before confirmation. Cancellation, rescheduling and refund requests are subject to the policy communicated for the relevant service or plan and applicable law. Check the applicable policy before payment.',
                  'लागू कीमत और प्लान का विवरण पुष्टि से पहले दिखाया जाना चाहिए। कैंसलेशन, रीशेड्यूल और रिफंड संबंधित सेवा या प्लान की बताई गई नीति और लागू कानून के अनुसार होंगे। भुगतान से पहले संबंधित नीति जाँचें।',
                  'প্রযোজ্য মূল্য ও প্ল্যানের বিবরণ নিশ্চিতকরণের আগে দেখানো উচিত। বাতিল, পুনর্নির্ধারণ ও রিফান্ড সংশ্লিষ্ট পরিষেবা বা প্ল্যানের নীতি এবং প্রযোজ্য আইন অনুযায়ী হবে। পেমেন্টের আগে নীতি দেখে নিন।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '6. Service Issues and Complaints',
                  '6. सेवा संबंधी समस्या और शिकायत',
                  '৬. পরিষেবা সমস্যা ও অভিযোগ',
                  lang,
                ),
                _tr(
                  'If a booking, handover or walk does not go as expected, contact the support team and share the booking details. We will review the information and respond through the available support process.',
                  'यदि बुकिंग, डॉग सौंपने या वॉक में समस्या हो, तो बुकिंग विवरण के साथ सपोर्ट टीम से संपर्क करें। उपलब्ध सहायता प्रक्रिया के अनुसार जानकारी की समीक्षा की जाएगी।',
                  'বুকিং, কুকুর হস্তান্তর বা ওয়াকে সমস্যা হলে বুকিংয়ের বিবরণসহ সহায়তা দলের সঙ্গে যোগাযোগ করুন। উপলব্ধ সহায়তা প্রক্রিয়া অনুযায়ী বিষয়টি পর্যালোচনা করা হবে।',
                  lang,
                ),
              ),

              _section(
                _tr(
                  '7. Updates to These Terms',
                  '7. इन नियमों में बदलाव',
                  '৭. শর্তাবলির পরিবর্তন',
                  lang,
                ),
                _tr(
                  'These terms may be updated when the service or applicable requirements change. The published version should state its effective date. Significant changes should be communicated where required by law.',
                  'सेवा या कानूनी आवश्यकताओं में बदलाव होने पर इन नियमों को अपडेट किया जा सकता है। प्रकाशित संस्करण में लागू होने की तारीख होनी चाहिए। कानून के अनुसार जरूरी महत्वपूर्ण बदलावों की सूचना दी जानी चाहिए।',
                  'পরিষেবা বা আইনি প্রয়োজন পরিবর্তিত হলে এই শর্তাবলি আপডেট করা হতে পারে। প্রকাশিত সংস্করণে কার্যকর হওয়ার তারিখ থাকা উচিত। আইন অনুযায়ী গুরুত্বপূর্ণ পরিবর্তনের বিজ্ঞপ্তি দেওয়া উচিত।',
                  lang,
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _tr(
                    'Important: This is a draft template. Before publishing, DOJO WALK must verify that it matches its actual data practices, service operations, cancellation and refund policies, applicable Indian laws, official contact details and effective date. It is not a substitute for legal review.',
                    'महत्वपूर्ण: यह एक ड्राफ्ट है। प्रकाशित करने से पहले DOJO WALK को वास्तविक डेटा प्रक्रिया, सेवा संचालन, कैंसलेशन और रिफंड नीति, लागू भारतीय कानून, आधिकारिक संपर्क विवरण और लागू होने की तारीख की जाँच करनी चाहिए। यह कानूनी सलाह का विकल्प नहीं है।',
                    'গুরুত্বপূর্ণ: এটি একটি খসড়া। প্রকাশের আগে DOJO WALK-কে বাস্তব তথ্য ব্যবহারের পদ্ধতি, পরিষেবা পরিচালনা, বাতিল ও রিফান্ড নীতি, প্রযোজ্য ভারতীয় আইন, সরকারি যোগাযোগের তথ্য এবং কার্যকর হওয়ার তারিখ যাচাই করতে হবে। এটি আইনি পরামর্শের বিকল্প নয়।',
                    lang,
                  ),
                  style: const TextStyle(
                    color: _textColor,
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              Center(
                child: Text(
                  'DOJO WALK',
                  style: TextStyle(
                    color: _orange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _heading(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _orange, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0E8DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: _textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              height: 1.65,
              color: _mutedColor,
            ),
          ),
        ],
      ),
    );
  }
}
