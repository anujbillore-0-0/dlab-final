import 'package:flutter/material.dart';

import 'order_return_confirm_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedText = Color(0xFF6B7280);

class UploadEvidenceScreen extends StatefulWidget {
  const UploadEvidenceScreen({required this.payload, super.key});

  final ReturnEvidencePayload payload;

  @override
  State<UploadEvidenceScreen> createState() => _UploadEvidenceScreenState();
}

class _UploadEvidenceScreenState extends State<UploadEvidenceScreen> {
  late List<ReturnEvidenceMedia> _media;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _media = [...widget.payload.initialEvidence];
  }

  Future<void> _onTapUploadArea() async {
    if (_media.length >= 5) {
      _showMessage('You can upload up to 5 images');
      return;
    }

    // Future integration point:
    // open file/image picker and append selected evidence files to _media.
    _showMessage('Image picker integration coming soon');
  }

  void _removeMedia(String id) {
    setState(() {
      _media = _media.where((item) => item.id != id).toList();
    });
  }

  Future<void> _onContinue() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await ReturnEvidenceService.saveEvidenceDraft(
        payload: widget.payload,
        media: _media,
      );
      if (!mounted) return;

      final confirmPayload = ReturnConfirmPayload(
        orderId: widget.payload.orderId,
        itemTitles:
            widget.payload.selectedItems.map((item) => item.title).toList(),
        reasonTitle: widget.payload.selectedReasonTitle,
        evidenceCount: _media.length,
        refundSummary: const ReturnRefundSummary(totalRefundLabel: r'$1300'),
        pickupWindow: const ReturnPickupWindow(
          title: 'Doorstep Pickup',
          subtitle: 'Free pickup on March 28, 2025 (9 AM - 6 PM)',
        ),
        guidanceMessage:
            'Please keep the product in original packaging with all accessories ready for pickup.',
      );

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReturnConfirmScreen(payload: confirmPayload),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Failed to save evidence. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
                      'Upload Evidence',
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
                  InkWell(
                    onTap: _onTapUploadArea,
                    borderRadius: BorderRadius.circular(10),
                    child: Ink(
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0x1A62B6CB),
                        border: Border.all(color: _secondaryColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.cloud_upload_rounded,
                            color: _secondaryColor,
                            size: 40,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Drag & drop or click to upload',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Upload images of the product showing the issue',
                            style: TextStyle(
                              color: Color(0xFF999999),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children:
                        _media
                            .map(
                              (item) => _EvidenceThumb(
                                item: item,
                                onRemove: () => _removeMedia(item.id),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 20),
                  Container(
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
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1),
                          child: Icon(
                            Icons.access_time_filled,
                            color: Color(0xFFAD0000),
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Clear photos help process your return faster. Max 5 images, up to 10MB each.',
                            style: TextStyle(
                              color: _mutedText,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
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
            onPressed: _isSubmitting ? null : _onContinue,
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
                      'Continue',
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

class _EvidenceThumb extends StatelessWidget {
  const _EvidenceThumb({required this.item, required this.onRemove});

  final ReturnEvidenceMedia item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              border: Border.all(color: _mutedText),
              borderRadius: BorderRadius.circular(10),
              color: const Color(0xFFD9D9D9),
              image:
                  item.imageUrl != null && item.imageUrl!.isNotEmpty
                      ? DecorationImage(
                        image: NetworkImage(item.imageUrl!),
                        fit: BoxFit.cover,
                      )
                      : null,
            ),
            alignment: Alignment.center,
            child:
                item.imageUrl == null || item.imageUrl!.isEmpty
                    ? Icon(
                      item.fallbackIcon,
                      size: 42,
                      color: const Color(0xFF1F2937),
                    )
                    : null,
          ),
          Positioned(
            top: -7,
            right: -8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF383C),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReturnEvidencePayload {
  const ReturnEvidencePayload({
    required this.orderId,
    required this.selectedReasonId,
    required this.selectedReasonTitle,
    required this.note,
    required this.selectedItems,
    required this.initialEvidence,
  });

  final String orderId;
  final String selectedReasonId;
  final String selectedReasonTitle;
  final String note;
  final List<ReturnEvidenceItem> selectedItems;
  final List<ReturnEvidenceMedia> initialEvidence;

  factory ReturnEvidencePayload.dummy() {
    return const ReturnEvidencePayload(
      orderId: 'DLAB-2025-001234',
      selectedReasonId: 'defective',
      selectedReasonTitle: 'Defective / Damaged',
      note: '',
      selectedItems: [
        ReturnEvidenceItem(
          id: 'item-1',
          title: 'Apple MacBook Pro Core i9 9th Gen',
          quantity: 1,
          priceLabel: 'INR 2,24,900',
        ),
      ],
      initialEvidence: [
        ReturnEvidenceMedia(id: 'ev-1', fallbackIcon: Icons.headphones_rounded),
        ReturnEvidenceMedia(id: 'ev-2', fallbackIcon: Icons.cable_rounded),
      ],
    );
  }
}

class ReturnEvidenceItem {
  const ReturnEvidenceItem({
    required this.id,
    required this.title,
    required this.quantity,
    required this.priceLabel,
  });

  final String id;
  final String title;
  final int quantity;
  final String priceLabel;
}

class ReturnEvidenceMedia {
  const ReturnEvidenceMedia({
    required this.id,
    required this.fallbackIcon,
    this.imageUrl,
  });

  final String id;
  final IconData fallbackIcon;
  final String? imageUrl;
}

class ReturnEvidenceService {
  static Future<void> saveEvidenceDraft({
    required ReturnEvidencePayload payload,
    required List<ReturnEvidenceMedia> media,
  }) async {
    // Future integration point:
    // upload media files + payload to backend and link to return request.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
