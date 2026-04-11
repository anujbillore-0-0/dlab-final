import 'package:flutter/material.dart';

import 'order_return_upload_evidence_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedText = Color(0xFF6B7280);

class OrderReturnScreen extends StatefulWidget {
  const OrderReturnScreen({this.initialData, super.key});

  final OrderReturnViewModel? initialData;

  @override
  State<OrderReturnScreen> createState() => _OrderReturnScreenState();
}

class _OrderReturnScreenState extends State<OrderReturnScreen> {
  late final OrderReturnViewModel _data;
  final TextEditingController _notesController = TextEditingController();

  late Set<String> _selectedItemIds;
  String _selectedReasonId = _returnReasonOptions.first.id;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? OrderReturnViewModel.dummy();
    _selectedItemIds =
        _data.items
            .where((item) => item.selectedByDefault)
            .map((item) => item.id)
            .toSet();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleItemSelection(String itemId) {
    setState(() {
      if (_selectedItemIds.contains(itemId)) {
        _selectedItemIds.remove(itemId);
      } else {
        _selectedItemIds.add(itemId);
      }
    });
  }

  Future<void> _onContinueToUpload() async {
    if (_selectedItemIds.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Select at least one item to continue')),
        );
      return;
    }

    final selectedReason = _returnReasonOptions.firstWhere(
      (reason) => reason.id == _selectedReasonId,
    );

    final selectedItems =
        _data.items
            .where((item) => _selectedItemIds.contains(item.id))
            .toList();

    final draft = ReturnRequestDraft(
      orderId: _data.orderId,
      selectedReasonId: selectedReason.id,
      selectedReasonTitle: selectedReason.title,
      note: _notesController.text.trim(),
      items: selectedItems,
    );

    await ReturnRequestService.saveDraft(draft);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder:
            (_) => UploadEvidenceScreen(
              payload: ReturnEvidencePayload(
                orderId: draft.orderId,
                selectedReasonId: draft.selectedReasonId,
                selectedReasonTitle: draft.selectedReasonTitle,
                note: draft.note,
                selectedItems:
                    selectedItems
                        .map(
                          (item) => ReturnEvidenceItem(
                            id: item.id,
                            title: item.title,
                            quantity: item.quantity,
                            priceLabel: item.priceLabel,
                          ),
                        )
                        .toList(),
                initialEvidence: const [
                  ReturnEvidenceMedia(
                    id: 'ev-1',
                    fallbackIcon: Icons.headphones_rounded,
                  ),
                  ReturnEvidenceMedia(
                    id: 'ev-2',
                    fallbackIcon: Icons.cable_rounded,
                  ),
                ],
              ),
            ),
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
                      'order return',
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
                  _ReturnOrderSummaryCard(data: _data),
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
                  ..._data.items.map(
                    (item) => _ReturnItemCard(
                      item: item,
                      isSelected: _selectedItemIds.contains(item.id),
                      onTap: () => _toggleItemSelection(item.id),
                    ),
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
                  ..._returnReasonOptions.map((option) {
                    final isSelected = option.id == _selectedReasonId;
                    return _ReasonOptionTile(
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
            onPressed: _onContinueToUpload,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Continue to Upload',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnOrderSummaryCard extends StatelessWidget {
  const _ReturnOrderSummaryCard({required this.data});

  final OrderReturnViewModel data;

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
            'Order #${data.orderId}',
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Placed on ${data.placedOnLabel}',
            style: const TextStyle(
              color: _mutedText,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Total: ${data.totalLabel}',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Return window closes: ${data.returnWindowClosesLabel}',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReturnItemCard extends StatelessWidget {
  const _ReturnItemCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ReturnOrderItem item;
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
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _secondaryColor,
                width: isSelected ? 1 : 0.5,
              ),
              boxShadow:
                  isSelected
                      ? const [
                        BoxShadow(
                          color: Color(0x26000000),
                          blurRadius: 7.3,
                          offset: Offset(0, 0),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                _ReturnItemThumb(imageUrl: item.imageUrl),
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
                const SizedBox(width: 8),
                Icon(
                  isSelected
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 30,
                  color: _primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReturnItemThumb extends StatelessWidget {
  const _ReturnItemThumb({required this.imageUrl});

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

class _ReasonOptionTile extends StatelessWidget {
  const _ReasonOptionTile({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ReturnReasonOption option;
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
                color: const Color(0xFFCAE9FF),
                width: isSelected ? 1 : 0.5,
              ),
              boxShadow:
                  isSelected
                      ? const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 10,
                          offset: Offset(0, 0),
                        ),
                      ]
                      : null,
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected ? _primaryColor : _mutedText,
                  size: 30,
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

class OrderReturnViewModel {
  const OrderReturnViewModel({
    required this.orderId,
    required this.placedOnLabel,
    required this.totalLabel,
    required this.returnWindowClosesLabel,
    required this.items,
  });

  final String orderId;
  final String placedOnLabel;
  final String totalLabel;
  final String returnWindowClosesLabel;
  final List<ReturnOrderItem> items;

  factory OrderReturnViewModel.dummy() {
    return OrderReturnViewModel(
      orderId: 'DLAB-2025-001234',
      placedOnLabel: 'March 20, 2025',
      totalLabel: 'INR 1,57,499',
      returnWindowClosesLabel: 'April 8, 2025',
      items: const [
        ReturnOrderItem(
          id: 'item-1',
          title: 'Apple MacBook Pro Core i9 9th Gen',
          quantity: 1,
          priceLabel: 'INR 2,24,900',
          selectedByDefault: true,
        ),
        ReturnOrderItem(
          id: 'item-2',
          title: 'Apple MacBook Pro Core i9 9th Gen',
          quantity: 1,
          priceLabel: 'INR 2,24,900',
          selectedByDefault: false,
        ),
      ],
    );
  }
}

class ReturnOrderItem {
  const ReturnOrderItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.priceLabel,
    required this.selectedByDefault,
    this.imageUrl,
  });

  final String id;
  final String title;
  final int quantity;
  final String priceLabel;
  final bool selectedByDefault;
  final String? imageUrl;
}

class ReturnReasonOption {
  const ReturnReasonOption({
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final String id;
  final String title;
  final String subtitle;
}

class ReturnRequestDraft {
  const ReturnRequestDraft({
    required this.orderId,
    required this.selectedReasonId,
    required this.selectedReasonTitle,
    required this.note,
    required this.items,
  });

  final String orderId;
  final String selectedReasonId;
  final String selectedReasonTitle;
  final String note;
  final List<ReturnOrderItem> items;
}

class ReturnRequestService {
  static Future<void> saveDraft(ReturnRequestDraft draft) async {
    // Future integration point:
    // Persist draft to backend/local DB before navigating to upload flow.
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

const _returnReasonOptions = [
  ReturnReasonOption(
    id: 'defective',
    title: 'Defective / Damaged',
    subtitle: 'Product arrived damaged or not working',
  ),
  ReturnReasonOption(
    id: 'wrong_item',
    title: 'Wrong item received',
    subtitle: 'Different from what I ordered',
  ),
  ReturnReasonOption(
    id: 'quality_issues',
    title: 'Quality issues',
    subtitle: 'Not as described, poor quality',
  ),
  ReturnReasonOption(
    id: 'size_fit',
    title: 'Size / Fit issues',
    subtitle: 'Does not fit as expected',
  ),
  ReturnReasonOption(
    id: 'other_reason',
    title: 'Other reason',
    subtitle: 'Please specify below',
  ),
];
