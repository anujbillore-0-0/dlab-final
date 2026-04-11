import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'order_cancellation_screen.dart';

const _primaryColor = Color(0xFF1B4965);
const _secondaryColor = Color(0xFF62B6CB);
const _mutedText = Color(0xFF6B7280);
const _dividerColor = Color(0xFFDADADA);
const _successColor = Color(0xFF26A541);

class TrackOrderScreen extends StatelessWidget {
  const TrackOrderScreen({
    required this.orderId,
    required this.productTitle,
    required this.deliveredOnLabel,
    this.imageUrl,
    super.key,
  });

  final String orderId;
  final String productTitle;
  final String deliveredOnLabel;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final data = TrackOrderViewModel.dummy(
      orderId: orderId,
      productTitle: productTitle,
      deliveredOnLabel: deliveredOnLabel,
      imageUrl: imageUrl,
    );

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
                      'My Orders',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(content: Text('Share coming soon')),
                        );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _OrderHeaderCard(data: data),
                  const SizedBox(height: 12),
                  _EstimatedDeliveryCard(data: data),
                  const SizedBox(height: 12),
                  const _RatingCard(),
                  const SizedBox(height: 18),
                  const Text(
                    'Order Status Timeline',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 33 / 1.65,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TimelineSection(events: data.timeline),
                  const Divider(
                    height: 26,
                    thickness: 0.5,
                    color: _dividerColor,
                  ),
                  const Text(
                    'Items in this order',
                    style: TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 33 / 1.65,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...data.items.map((item) => _OrderLineItemCard(item: item)),
                  const SizedBox(height: 12),
                  _DeliveryAddressCard(address: data.address),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => OrderCancellationScreen(
                            orderId: data.orderId,
                            placedOnLabel: data.placedOnLabel,
                            totalLabel: data.totalLabel,
                            items:
                                data.items
                                    .map(
                                      (item) => CancellationOrderItem(
                                        title: item.title,
                                        quantity: item.quantity,
                                        priceLabel: item.priceLabel,
                                        imageUrl: item.imageUrl,
                                      ),
                                    )
                                    .toList(),
                          ),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  side: const BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Cancel Order',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Map tracking coming soon')),
                    );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Track on map',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.data});

  final TrackOrderViewModel data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              _ProductThumb(imageUrl: data.imageUrl, size: 91),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.deliveredOnLabel,
                      style: const TextStyle(
                        color: Color(0xFF111827),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1F2937),
                        fontSize: 32 / 2.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _mutedText,
                size: 28,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Order ID: #${data.orderId}',
                style: const TextStyle(
                  color: _mutedText,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: data.orderId));
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    const SnackBar(content: Text('Order ID copied')),
                  );
              },
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.copy_outlined,
                  color: _primaryColor,
                  size: 17,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EstimatedDeliveryCard extends StatelessWidget {
  const _EstimatedDeliveryCard({required this.data});

  final TrackOrderViewModel data;

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
                  data.estimatedTitle,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.estimatedDateLabel,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  data.estimatedSubtext,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

class _RatingCard extends StatelessWidget {
  const _RatingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              6,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  Icons.star_rounded,
                  size: 34,
                  color: Color(0xFFE6E6E6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Rate this product now',
            style: TextStyle(
              color: _mutedText,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.events});

  final List<TrackTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(events.length, (index) {
        final event = events[index];
        final isLast = index == events.length - 1;
        return _TimelineRow(event: event, showConnector: !isLast);
      }),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.event, required this.showConnector});

  final TrackTimelineEvent event;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final dotSize = event.isCurrent ? 35.0 : 25.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.isDone ? _successColor : _mutedText,
                    border: Border.all(
                      color: event.isDone ? _successColor : _mutedText,
                      width: 1.5,
                    ),
                    boxShadow:
                        event.isCurrent
                            ? const [
                              BoxShadow(
                                color: Color(0x88000000),
                                blurRadius: 4,
                              ),
                            ]
                            : null,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: event.isDone ? _successColor : _mutedText,
                    ),
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: event.isDone ? _successColor : Colors.black12,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Color(0xFF111827),
                      fontSize: 31 / 1.95,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    event.timeLabel,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: const TextStyle(
                      color: _mutedText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.2,
                    ),
                  ),
                  if (event.extraLine != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      event.extraLine!,
                      style: const TextStyle(
                        color: _secondaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderLineItemCard extends StatelessWidget {
  const _OrderLineItemCard({required this.item});

  final TrackOrderLineItem item;

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
          _ProductThumb(imageUrl: item.imageUrl, size: 89),
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
                    color: Color(0xFFFF5500),
                    fontSize: 34 / 1.7,
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

class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({required this.address});

  final DeliveryAddress address;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Icons.location_on,
              color: _primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery Address',
                  style: TextStyle(
                    color: _primaryColor,
                    fontSize: 34 / 1.7,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address.name,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address.fullAddress,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  address.phone,
                  style: const TextStyle(
                    color: _primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
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

class _ProductThumb extends StatelessWidget {
  const _ProductThumb({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
              ? Icon(
                Icons.headphones_rounded,
                size: size * 0.42,
                color: const Color(0xFF9CA3AF),
              )
              : null,
    );
  }
}

class TrackOrderViewModel {
  const TrackOrderViewModel({
    required this.orderId,
    required this.placedOnLabel,
    required this.totalLabel,
    required this.productTitle,
    required this.deliveredOnLabel,
    required this.imageUrl,
    required this.estimatedTitle,
    required this.estimatedDateLabel,
    required this.estimatedSubtext,
    required this.timeline,
    required this.items,
    required this.address,
  });

  final String orderId;
  final String placedOnLabel;
  final String totalLabel;
  final String productTitle;
  final String deliveredOnLabel;
  final String? imageUrl;
  final String estimatedTitle;
  final String estimatedDateLabel;
  final String estimatedSubtext;
  final List<TrackTimelineEvent> timeline;
  final List<TrackOrderLineItem> items;
  final DeliveryAddress address;

  factory TrackOrderViewModel.dummy({
    required String orderId,
    required String productTitle,
    required String deliveredOnLabel,
    String? imageUrl,
  }) {
    return TrackOrderViewModel(
      orderId: orderId,
      placedOnLabel: 'March 20, 2025',
      totalLabel: 'INR 1,57,499',
      productTitle: productTitle,
      deliveredOnLabel: deliveredOnLabel,
      imageUrl: imageUrl,
      estimatedTitle: 'Estimated Delivery',
      estimatedDateLabel: 'Wednesday, March 26, 2025',
      estimatedSubtext: 'Your package is on the way!',
      timeline: const [
        TrackTimelineEvent(
          title: 'Order Placed',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Your order has been confirmed and payment received.',
          isDone: true,
        ),
        TrackTimelineEvent(
          title: 'Order Confirmed',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Your order has been verified and confirmed by seller.',
          isDone: true,
        ),
        TrackTimelineEvent(
          title: 'Processing',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Seller is preparing your items for shipment.',
          isDone: true,
        ),
        TrackTimelineEvent(
          title: 'Shipped',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Your package has been handed over to courier partner.',
          extraLine: 'Courier: Blue Dart Express • Tracking: BD123456789',
          isDone: true,
        ),
        TrackTimelineEvent(
          title: 'Out for Delivery',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Your package is out for delivery. Driver: john',
          extraLine: 'Estimated arrival: 11:00 AM - 1:00 PM',
          isDone: true,
          isCurrent: true,
        ),
        TrackTimelineEvent(
          title: 'Delivered',
          timeLabel: 'March 20, 2025 • 10:32 AM',
          description: 'Package delivered to your address.',
          isDone: false,
        ),
      ],
      items: List.generate(
        3,
        (_) => TrackOrderLineItem(
          title: 'Apple MacBook Pro Core i9 9th Gen',
          quantity: 1,
          priceLabel: 'INR 2,24,900',
          imageUrl: imageUrl,
        ),
      ),
      address: const DeliveryAddress(
        name: 'Alex Chen',
        fullAddress: '123 Orchard Road, #12-34, Singapore 238888',
        phone: '+65 9123 4567',
      ),
    );
  }
}

class TrackTimelineEvent {
  const TrackTimelineEvent({
    required this.title,
    required this.timeLabel,
    required this.description,
    required this.isDone,
    this.extraLine,
    this.isCurrent = false,
  });

  final String title;
  final String timeLabel;
  final String description;
  final String? extraLine;
  final bool isDone;
  final bool isCurrent;
}

class TrackOrderLineItem {
  const TrackOrderLineItem({
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

class DeliveryAddress {
  const DeliveryAddress({
    required this.name,
    required this.fullAddress,
    required this.phone,
  });

  final String name;
  final String fullAddress;
  final String phone;
}
