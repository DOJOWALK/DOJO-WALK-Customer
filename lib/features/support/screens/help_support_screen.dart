import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../l10n/app_localizations.dart';

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

  final List<Map<String, String>> _faqs = const [
    {'question': 'supportFaqBookQuestion', 'answer': 'supportFaqBookAnswer'},
    {'question': 'supportFaqRegularQuestion', 'answer': 'supportFaqRegularAnswer'},
    {'question': 'supportFaqDogQuestion', 'answer': 'supportFaqDogAnswer'},
    {'question': 'supportFaqCancelQuestion', 'answer': 'supportFaqCancelAnswer'},
    {'question': 'supportFaqWalkerQuestion', 'answer': 'supportFaqWalkerAnswer'},
    {'question': 'supportFaqPaymentQuestion', 'answer': 'supportFaqPaymentAnswer'},
  ];

  String _faqText(AppLocalizations l10n, String key) => switch (key) {
        'supportFaqBookQuestion' => l10n.supportFaqBookQuestion,
        'supportFaqBookAnswer' => l10n.supportFaqBookAnswer,
        'supportFaqRegularQuestion' => l10n.supportFaqRegularQuestion,
        'supportFaqRegularAnswer' => l10n.supportFaqRegularAnswer,
        'supportFaqDogQuestion' => l10n.supportFaqDogQuestion,
        'supportFaqDogAnswer' => l10n.supportFaqDogAnswer,
        'supportFaqCancelQuestion' => l10n.supportFaqCancelQuestion,
        'supportFaqCancelAnswer' => l10n.supportFaqCancelAnswer,
        'supportFaqWalkerQuestion' => l10n.supportFaqWalkerQuestion,
        'supportFaqWalkerAnswer' => l10n.supportFaqWalkerAnswer,
        'supportFaqPaymentQuestion' => l10n.supportFaqPaymentQuestion,
        _ => l10n.supportFaqPaymentAnswer,
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
          content: Text(l10n.supportMessageNotSent),
          backgroundColor: supportOrange,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
          backgroundColor: supportBackground,
          appBar: AppBar(
            backgroundColor: supportBackground,
            foregroundColor: supportText,
            elevation: 0,
            title: Text(
              AppLocalizations.of(context).helpAndSupport,
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
                          Text(AppLocalizations.of(context).supportHowCanWeHelp,
                              style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(AppLocalizations.of(context).supportIntro, style: const TextStyle(color: Colors.white, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(AppLocalizations.of(context).supportFaqTitle,
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
                        title: Text(_faqText(l10n, _faqs[i]['question']!),
                            style: const TextStyle(color: supportText, fontWeight: FontWeight.w700, fontSize: 14)),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_faqText(l10n, _faqs[i]['answer']!),
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
              Text(AppLocalizations.of(context).supportStillNeedHelp,
                  style: const TextStyle(color: supportText, fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(AppLocalizations.of(context).supportDescribeIssueBelow,
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
                      Text(AppLocalizations.of(context).supportTopicPrompt,
                          style: const TextStyle(color: supportText, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<String>(
                        initialValue: _category,
                        isExpanded: true,
                        decoration: _inputDecoration(AppLocalizations.of(context).supportSelectTopic),
                        items: [
                          DropdownMenuItem(value: 'Booking', child: Text(AppLocalizations.of(context).supportBookingCategory)),
                          DropdownMenuItem(value: 'Regular Walk Plan', child: Text(AppLocalizations.of(context).supportRegularPlanCategory)),
                          DropdownMenuItem(value: 'Walker', child: Text(AppLocalizations.of(context).supportWalkerCategory)),
                          DropdownMenuItem(value: 'Payment', child: Text(AppLocalizations.of(context).supportPaymentCategory)),
                          DropdownMenuItem(value: 'My Dogs', child: Text(AppLocalizations.of(context).supportDogsCategory)),
                          DropdownMenuItem(value: 'Safety', child: Text(AppLocalizations.of(context).supportSafetyCategory)),
                          DropdownMenuItem(value: 'Other', child: Text(AppLocalizations.of(context).supportOtherCategory)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _category = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(AppLocalizations.of(context).supportDescribeIssue,
                          style: const TextStyle(color: supportText, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 9),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _inputDecoration(AppLocalizations.of(context).supportMessageHint),
                        validator: (value) {
                          if (value == null || value.trim().length < 10) {
                            return AppLocalizations.of(context).supportMinCharacters;
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
                          label: Text(AppLocalizations.of(context).supportSubmitRequest,
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
                      Text(AppLocalizations.of(context).supportFormNotConnected, style: const TextStyle(color: supportMuted, fontSize: 12, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
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
