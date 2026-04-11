import 'package:flutter/material.dart';

import 'order_cancellation_confirm_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _mutedText = Color(0xFF6B7280);
const _optionBorder = Color(0xFFCAE9FF);

class OrderCancellationScreen extends StatefulWidget {
  const OrderCancellationScreen({
    required this.orderId,
    required this.placedOnLabel,
    required this.totalLabel,
    required this.items,
    super.key,
  });

  final String orderId;
  final String placedOnLabel;
  final String totalLabel;
  final List<CancellationOrderItem> items;

  @override
  State<OrderCancellationScreen> createState() =>
      _OrderCancellationScreenState();
}

class _OrderCancellationScreenState extends State<OrderCancellationScreen> {
  final TextEditingController _notesController = TextEditingController();

  String _selectedReasonId = _reasonOptions.first.id;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  CancellationReasonOption get _selectedReason {
    return _reasonOptions.firstWhere(
      (reason) => reason.id == _selectedReasonId,
    );
  }

  void _submit() {
    final note = _notesController.text.trim();
    final draft = CancellationRequestDraft(
      orderId: widget.orderId,
      placedOnLabel: widget.placedOnLabel,
      totalLabel: widget.totalLabel,
      reasonId: _selectedReason.id,
      reasonTitle: _selectedReason.title,
      note: note,
      items:
          widget.items
              .map(
                (item) => CancellationDraftItem(
                  title: item.title,
                  quantity: item.quantity,
                  priceLabel: item.priceLabel,
                  imageUrl: item.imageUrl,
                ),
              )
              .toList(),
    );

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OrderCancellationConfirmScreen(draft: draft),
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
                    onTap: () => Navigator.of(context).pop(),
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
                      'order cancellation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _OrderSummaryCard(
                    orderId: widget.orderId,
                    placedOnLabel: widget.placedOnLabel,
                    totalLabel: widget.totalLabel,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Items in order',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.items.map(
                    (item) => _CancellationItemCard(item: item),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Reason for cancellation',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._reasonOptions.map((option) {
                    final isSelected = option.id == _selectedReasonId;
                    return _CancellationReasonTile(
                      option: option,
                      isSelected: isSelected,
                      onTap:
                          () => setState(() => _selectedReasonId = option.id),
                    );
                  }),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell us more (optional)',
                      hintStyle: const TextStyle(
                        color: Color(0xFF999999),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _primaryColor),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue to cancellation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({
    required this.orderId,
    required this.placedOnLabel,
    required this.totalLabel,
  });

  final String orderId;
  final String placedOnLabel;
  final String totalLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order #$orderId',
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Placed on $placedOnLabel',
            style: const TextStyle(
              color: _mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Total: $totalLabel',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CancellationItemCard extends StatelessWidget {
  const _CancellationItemCard({required this.item});

  final CancellationOrderItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
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
      child: Row(
        children: [
          _ItemThumb(imageUrl: item.imageUrl),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    color: _mutedText,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.priceLabel,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 40 / 1.7,
                    fontWeight: FontWeight.w800,
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

class _ItemThumb extends StatelessWidget {
  const _ItemThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 91,
      height: 91,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFF3F4F6),
        image:
            imageUrl != null && imageUrl!.isNotEmpty
                ? DecorationImage(
                  image: NetworkImage(imageUrl!),
                  fit: BoxFit.cover,
                )
                : null,
      ),
      alignment: Alignment.center,
      child:
          imageUrl == null || imageUrl!.isEmpty
              ? const Icon(
                Icons.headphones_rounded,
                size: 34,
                color: Color(0xFF9CA3AF),
              )
              : null,
    );
  }
}

class _CancellationReasonTile extends StatelessWidget {
  const _CancellationReasonTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final CancellationReasonOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _optionBorder,
                width: isSelected ? 1 : 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? _primaryColor : _mutedText,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        option.title,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        option.subtitle,
                        style: const TextStyle(
                          color: _mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CancellationOrderItem {
  const CancellationOrderItem({
    required this.title,
    required this.quantity,
    required this.priceLabel,
    this.imageUrl,
  });

  final String title;
  final int quantity;
  final String priceLabel;
  final String? imageUrl;
}

class CancellationReasonOption {
  const CancellationReasonOption({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

const _reasonOptions = [
  CancellationReasonOption(
    id: 'changed_mind',
    title: 'Changed my mind',
    subtitle: 'No longer need this product',
  ),
  CancellationReasonOption(
    id: 'better_price',
    title: 'Better price available',
    subtitle: 'Found a better deal elsewhere',
  ),
  CancellationReasonOption(
    id: 'ordered_by_mistake',
    title: 'Ordered by mistake',
    subtitle: 'Wrong product or quantity',
  ),
  CancellationReasonOption(
    id: 'shipping_too_slow',
    title: 'Shipping too slow',
    subtitle: 'Delivery time not acceptable',
  ),
  CancellationReasonOption(
    id: 'other_reason',
    title: 'Other reason',
    subtitle: 'Please specify below',
  ),
];
