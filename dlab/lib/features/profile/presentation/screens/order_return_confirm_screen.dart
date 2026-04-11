import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const _primaryColor = Color(0xFF1B4965);
const _mutedText = Color(0xFF6B7280);

class ReturnConfirmScreen extends StatefulWidget {
  const ReturnConfirmScreen({required this.payload, super.key});

  final ReturnConfirmPayload payload;

  @override
  State<ReturnConfirmScreen> createState() => _ReturnConfirmScreenState();
}

class _ReturnConfirmScreenState extends State<ReturnConfirmScreen> {
  bool _isSubmitting = false;

  Future<void> _onConfirmReturn() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await ReturnConfirmService.submitReturn(widget.payload);
      if (!mounted) return;
      await _showReturnDonePopup(result);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Failed to confirm return')),
        );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showReturnDonePopup(ReturnSubmissionResult result) async {
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
              boxShadow: const [
                BoxShadow(
                  color: Color(0x52091F3A),
                  blurRadius: 10,
                  offset: Offset(0, 8),
                ),
              ],
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
                Text(
                  result.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  result.message,
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
                      'Confirm Return',
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
                  _ReturnSummaryCard(payload: widget.payload),
                  const SizedBox(height: 20),
                  _PickupCard(pickup: widget.payload.pickupWindow),
                  const SizedBox(height: 20),
                  _InfoCard(message: widget.payload.guidanceMessage),
                  const SizedBox(height: 30),
                  const SizedBox(height: 120),
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
            onPressed: _isSubmitting ? null : _onConfirmReturn,
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
                      'Confirm Return',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

class _ReturnSummaryCard extends StatelessWidget {
  const _ReturnSummaryCard({required this.payload});

  final ReturnConfirmPayload payload;

  @override
  Widget build(BuildContext context) {
    final summary = payload.refundSummary;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Return Summary',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 80,
                      child: Text(
                        'Item',
                        style: TextStyle(
                          color: Color(0xFF0B1527),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children:
                            payload.itemTitles
                                .map(
                                  (title) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                        color: _primaryColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: -0.02,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Reason',
                        style: TextStyle(
                          color: Color(0xFF0B1527),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.02,
                        ),
                      ),
                    ),
                    Text(
                      payload.reasonTitle,
                      style: const TextStyle(
                        color: _primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.02,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFDADADA)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Refund',
                    style: TextStyle(
                      color: Color(0xFF0B1527),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.02,
                    ),
                  ),
                ),
                Text(
                  summary.totalRefundLabel,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.02,
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

class _PickupCard extends StatelessWidget {
  const _PickupCard({required this.pickup});

  final ReturnPickupWindow pickup;

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
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFCAE9FF),
              borderRadius: BorderRadius.circular(5),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.local_shipping_rounded,
              color: _primaryColor,
              size: 35,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pickup.title,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  pickup.subtitle,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.message});

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
              color: Color(0xFFAD0000),
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

class ReturnConfirmPayload {
  const ReturnConfirmPayload({
    required this.orderId,
    required this.itemTitles,
    required this.reasonTitle,
    required this.evidenceCount,
    required this.refundSummary,
    required this.pickupWindow,
    required this.guidanceMessage,
  });

  final String orderId;
  final List<String> itemTitles;
  final String reasonTitle;
  final int evidenceCount;
  final ReturnRefundSummary refundSummary;
  final ReturnPickupWindow pickupWindow;
  final String guidanceMessage;

  factory ReturnConfirmPayload.dummy() {
    return const ReturnConfirmPayload(
      orderId: 'DLAB-2025-001234',
      itemTitles: ['Sony WH-1000XM4 Headphones', 'Sony WH-1000XM4 Headphones'],
      reasonTitle: 'Defective / Damaged',
      evidenceCount: 2,
      refundSummary: ReturnRefundSummary(totalRefundLabel: r'$1300'),
      pickupWindow: ReturnPickupWindow(
        title: 'Doorstep Pickup',
        subtitle: 'Free pickup on March 28, 2025 (9 AM - 6 PM)',
      ),
      guidanceMessage:
          'Please keep the product in original packaging with all accessories ready for pickup.',
    );
  }
}

class ReturnRefundSummary {
  const ReturnRefundSummary({required this.totalRefundLabel});

  final String totalRefundLabel;
}

class ReturnPickupWindow {
  const ReturnPickupWindow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

class ReturnConfirmService {
  static Future<ReturnSubmissionResult> submitReturn(
    ReturnConfirmPayload payload,
  ) async {
    // Future integration point:
    // send payload to backend, create return record, and get pickup confirmation.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return const ReturnSubmissionResult(
      title: 'Order Returned',
      message: 'Your order has been Returned successfully',
    );
  }
}

class ReturnSubmissionResult {
  const ReturnSubmissionResult({required this.title, required this.message});

  final String title;
  final String message;
}
