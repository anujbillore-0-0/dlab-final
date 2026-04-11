import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _primaryColor = Color(0xFF1B4965);
const _mutedText = Color(0xFF6B7280);
const _successColor = Color(0xFF0D7E25);
const _successBorder = Color(0xFF26A541);
const _dangerColor = Color(0xFFAD0000);

class OrderCancellationConfirmScreen extends StatefulWidget {
  const OrderCancellationConfirmScreen({required this.draft, super.key});

  final CancellationRequestDraft draft;

  @override
  State<OrderCancellationConfirmScreen> createState() =>
      _OrderCancellationConfirmScreenState();
}

class _OrderCancellationConfirmScreenState
    extends State<OrderCancellationConfirmScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmCancellation() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await CancellationConfirmService.submitCancellation(
        widget.draft,
      );
      if (!mounted) return;
      await _showCancellationDonePopup(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to confirm cancellation')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showCancellationDonePopup(
    CancellationConfirmationResult result,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0x33000000),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: 388,
            padding: const EdgeInsets.fromLTRB(30, 14, 30, 30),
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/Group.svg',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Order Cancelled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your order has been cancelled successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Cancellation ID: ${result.cancellationId}\n'
                  'Refund initiated on ${result.refundInitiatedOnLabel}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      if (!mounted) return;
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: const Color(0xFF62B6CB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final breakdown =
        widget.draft.breakdown ??
        CancellationMonetaryBreakdown.dummyFromDraft(widget.draft);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
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
            const SizedBox(height: 18),
            _RefundSummaryCard(breakdown: breakdown),
            const SizedBox(height: 20),
            _RefundBreakdownCard(
              orderId: widget.draft.orderId,
              breakdown: breakdown,
            ),
            const SizedBox(height: 20),
            _RefundInfoCard(message: breakdown.turnaroundMessage),
            const SizedBox(height: 110),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmCancellation,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child:
                    _isSubmitting
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Confirm Cancellation',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Keep order',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
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

class _RefundSummaryCard extends StatelessWidget {
  const _RefundSummaryCard({required this.breakdown});

  final CancellationMonetaryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x338BEDA0),
        border: Border.all(color: _successBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Refund summary',
            style: TextStyle(
              color: _primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Total: ${breakdown.summaryRefundLabel}',
            style: const TextStyle(
              color: _successColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            breakdown.refundMethodMessage,
            style: const TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundBreakdownCard extends StatelessWidget {
  const _RefundBreakdownCard({required this.orderId, required this.breakdown});

  final String orderId;
  final CancellationMonetaryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _mutedText, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order #$orderId',
                        style: const TextStyle(
                          color: _primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _AmountRow(
                  label: 'Item Total',
                  value: breakdown.itemTotalLabel,
                ),
                const SizedBox(height: 14),
                _AmountRow(label: 'Discount', value: breakdown.discountLabel),
                const SizedBox(height: 14),
                _AmountRow(
                  label: 'Delivery Fee',
                  value: breakdown.deliveryFeeLabel,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: _AmountRow(
              label: 'Total Refund',
              value: breakdown.totalRefundLabel,
              isEmphasis: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.isEmphasis = false,
  });

  final String label;
  final String value;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: const Color(0xFF0B1527),
      fontSize: isEmphasis ? 20 : 16,
      fontWeight: isEmphasis ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: -0.02,
    );

    final valueStyle = TextStyle(
      color: _primaryColor,
      fontSize: isEmphasis ? 20 : 16,
      fontWeight: isEmphasis ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: -0.02,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: textStyle), Text(value, style: valueStyle)],
    );
  }
}

class _RefundInfoCard extends StatelessWidget {
  const _RefundInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1AFF0000),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.access_time_filled,
              color: _dangerColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: _mutedText,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CancellationRequestDraft {
  const CancellationRequestDraft({
    required this.orderId,
    required this.placedOnLabel,
    required this.totalLabel,
    required this.reasonId,
    required this.reasonTitle,
    required this.note,
    required this.items,
    this.breakdown,
  });

  final String orderId;
  final String placedOnLabel;
  final String totalLabel;
  final String reasonId;
  final String reasonTitle;
  final String note;
  final List<CancellationDraftItem> items;
  final CancellationMonetaryBreakdown? breakdown;
}

class CancellationDraftItem {
  const CancellationDraftItem({
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

class CancellationMonetaryBreakdown {
  const CancellationMonetaryBreakdown({
    required this.summaryRefundLabel,
    required this.itemTotalLabel,
    required this.discountLabel,
    required this.deliveryFeeLabel,
    required this.totalRefundLabel,
    required this.refundMethodMessage,
    required this.turnaroundMessage,
  });

  final String summaryRefundLabel;
  final String itemTotalLabel;
  final String discountLabel;
  final String deliveryFeeLabel;
  final String totalRefundLabel;
  final String refundMethodMessage;
  final String turnaroundMessage;

  factory CancellationMonetaryBreakdown.dummyFromDraft(
    CancellationRequestDraft draft,
  ) {
    return CancellationMonetaryBreakdown(
      summaryRefundLabel: draft.totalLabel,
      itemTotalLabel: r'$230',
      discountLabel: r'$50',
      deliveryFeeLabel: 'Free',
      totalRefundLabel: r'$680',
      refundMethodMessage: 'Refund will be credited to original payment method',
      turnaroundMessage:
          'Refund will reflect in 3-5 business days after cancellation confirmation.',
    );
  }
}

class CancellationConfirmService {
  static Future<CancellationConfirmationResult> submitCancellation(
    CancellationRequestDraft draft,
  ) async {
    // Future integration point:
    // Send `draft` to your backend/Supabase function and persist cancellation state.
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return CancellationConfirmationResult.dummyFromDraft(draft);
  }
}

class CancellationConfirmationResult {
  const CancellationConfirmationResult({
    required this.cancellationId,
    required this.refundInitiatedOnLabel,
  });

  final String cancellationId;
  final String refundInitiatedOnLabel;

  factory CancellationConfirmationResult.dummyFromDraft(
    CancellationRequestDraft draft,
  ) {
    final normalizedOrderId = draft.orderId.trim();
    final cancellationId =
        normalizedOrderId.isEmpty
            ? 'CAN-2025-001234'
            : 'CAN-$normalizedOrderId';

    return CancellationConfirmationResult(
      cancellationId: cancellationId,
      refundInitiatedOnLabel: 'March 25, 2025',
    );
  }
}
