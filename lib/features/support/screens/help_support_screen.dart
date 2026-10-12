
import 'package:flutter/material.dart';

const Color supportOrange = Color(0xFFFF7900);
const Color supportBackground = Color(0xFFFFFAF5);
const Color supportText = Color(0xFF202020);
const Color supportMuted = Color(0xFF777777);

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();

  String _category = 'Booking';

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I book a dog walk?',
      'answer':
          'Open Home, tap Book a Walk, choose your walk type, select your dog, add the pickup address and choose your schedule.',
    },
    {
      'question': 'What is a Regular Walk plan?',
      'answer':
          'A Regular Walk plan is for continuing daily walks at your preferred time. Your final schedule and walker assignment should be confirmed by DOJO WALK.',
    },
    {
      'question': 'How can I manage my dog details?',
      'answer':
          'Open My Dogs to add a dog, update saved details or delete a dog you no longer need in your list.',
    },
    {
      'question': 'Can I cancel a booking?',
      'answer':
          'Open My Bookings and check the booking details for the available cancellation or cancellation-request option.',
    },
    {
      'question': 'What if my assigned walker is unavailable?',
      'answer':
          'Contact support with your booking details so the team can review the situation and advise you about the next steps.',
    },
    {
      'question': 'When is payment required?',
      'answer':
          'Check the payment details shown during your booking. Do not assume a booking is paid until the app confirms the payment status.',
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitRequest() {
    if (!_formKey.currentState!.validate()) return;

    // UI validation is implemented. Connect this action to the
    // approved Firebase support-request workflow before launch.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Your message is ready. Support request submission '
          'will be enabled after Firebase support integration.',
        ),
        backgroundColor: supportOrange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: supportBackground,
      appBar: AppBar(
        backgroundColor: supportBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: supportText),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            color: supportText,
            fontWeight: FontWeight.w900,
            fontSize: 21,
          ),
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
            child: const Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 43,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How can we help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Find answers about your dog walks and bookings.',
                        style: TextStyle(
                          color: Colors.white,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: supportText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
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
                    key: PageStorageKey<String>(
                      _faqs[i]['question']!,
                    ),
                    tilePadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      15, 0, 15, 16,
                    ),
                    iconColor: supportOrange,
                    collapsedIconColor: supportMuted,
                    title: Text(
                      _faqs[i]['question']!,
                      style: const TextStyle(
                        color: supportText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _faqs[i]['answer']!,
                          style: const TextStyle(
                            color: supportMuted,
                            height: 1.5,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (i != _faqs.length - 1)
                    const Divider(
                      height: 1,
                      indent: 15,
                      endIndent: 15,
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Still need help?',
            style: TextStyle(
              color: supportText,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Describe your issue below.',
            style: TextStyle(
              color: supportMuted,
              height: 1.4,
            ),
          ),
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
                  const Text(
                    'What do you need help with?',
                    style: TextStyle(
                      color: supportText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: _inputDecoration('Select a topic'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Booking',
                        child: Text('Booking'),
                      ),
                      DropdownMenuItem(
                        value: 'Regular Walk Plan',
                        child: Text('Regular Walk Plan'),
                      ),
                      DropdownMenuItem(
                        value: 'Walker',
                        child: Text('Walker'),
                      ),
                      DropdownMenuItem(
                        value: 'Payment',
                        child: Text('Payment'),
                      ),
                      DropdownMenuItem(
                        value: 'My Dogs',
                        child: Text('My Dogs'),
                      ),
                      DropdownMenuItem(
                        value: 'Safety',
                        child: Text('Safety'),
                      ),
                      DropdownMenuItem(
                        value: 'Other',
                        child: Text('Other'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Describe your issue',
                    style: TextStyle(
                      color: supportText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 5,
                    maxLength: 1000,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: _inputDecoration(
                      'Tell us what happened...',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 10) {
                        return 'Please enter at least 10 characters.';
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
                      label: const Text(
                        'Submit Support Request',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: supportOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Note: sending requests is not connected yet. '
                    'Your message will not be sent to the support team '
                    'until the Firebase integration is implemented.',
                    style: TextStyle(
                      color: supportMuted,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: supportBackground,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
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
          color: supportOrange,
          width: 1.5,
        ),
      ),
    );
  }
}
