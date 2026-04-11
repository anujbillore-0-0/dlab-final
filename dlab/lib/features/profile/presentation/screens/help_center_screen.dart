import 'package:flutter/material.dart';

const _primaryColor = Color(0xFF1B4965);
const _mutedTextColor = Color(0xFF6B7280);
const _primaryFontColor = Color(0xFF111827);
const _dividerColor = Color(0xFFDADADA);

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const List<_FaqItem> _faqs = [
    _FaqItem(
      question: 'How do I track my order?',
      answer:
          'Open Profile > My Orders, select your order, then view the order timeline or use Track on map when available.',
    ),
    _FaqItem(
      question: 'What is your return policy?',
      answer:
          'Go to Profile > Return & Cancellation to start a return request, pick a reason, and upload evidence to continue.',
    ),
    _FaqItem(
      question: 'How long does shipping take?',
      answer:
          'Estimated delivery and live status are shown per order inside My Orders and Track Order.',
    ),
    _FaqItem(
      question: 'How do I contact customer support?',
      answer:
          'Use Profile > Contact Us for chat, email, or WhatsApp support options as they become available.',
    ),
    _FaqItem(
      question: 'Is my payment information secure?',
      answer:
          'Yes! We use 256-bit SSL encryption to protect your payment information. We never store your full card details on our servers.',
    ),
  ];

  int _expandedIndex = 4;

  void _toggleFaq(int index) {
    setState(() {
      _expandedIndex = _expandedIndex == index ? -1 : index;
    });
  }

  void _onContactSupportTap() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Contact Support: Coming soon'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _primaryColor,
                        size: 30,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Help Center',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF0B1527),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: _dividerColor, thickness: 0.5),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedIndex == index;
                  return _FaqTile(
                    item: faq,
                    isExpanded: isExpanded,
                    onTap: () => _toggleFaq(index),
                  );
                },
                separatorBuilder:
                    (_, __) => const Divider(
                      height: 22,
                      color: _dividerColor,
                      thickness: 0.5,
                    ),
                itemCount: _faqs.length,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 7.3,
                      offset: Offset(0, 0),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      'Still need help?',
                      style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Our support team is here for you',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onContactSupportTap,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Contact Support',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.item,
    required this.isExpanded,
    required this.onTap,
  });

  final _FaqItem item;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final questionColor = isExpanded ? _primaryColor : _primaryFontColor;
    final iconColor = isExpanded ? _primaryColor : _mutedTextColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.question,
                    style: TextStyle(
                      color: questionColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 10),
                    Text(
                      item.answer,
                      style: const TextStyle(
                        color: _mutedTextColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.chevron_right_rounded,
              color: iconColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem({required this.question, required this.answer});

  final String question;
  final String answer;
}
