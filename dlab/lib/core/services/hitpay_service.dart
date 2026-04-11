import 'package:dio/dio.dart';

class HitPayConfiguration {
  const HitPayConfiguration({
    required this.apiKey,
    required this.baseUrl,
    required this.currency,
    required this.redirectUrl,
    required this.webhookUrl,
  });

  final String apiKey;
  final String baseUrl;
  final String currency;
  final String redirectUrl;
  final String webhookUrl;

  static HitPayConfiguration fromEnvironment() {
    return HitPayConfiguration(
      apiKey: const String.fromEnvironment('HITPAY_API_KEY', defaultValue: ''),
      baseUrl: const String.fromEnvironment(
        'HITPAY_BASE_URL',
        defaultValue: 'https://api.hit-pay.com/v1',
      ),
      currency: const String.fromEnvironment('HITPAY_CURRENCY', defaultValue: 'SGD'),
      redirectUrl: const String.fromEnvironment('HITPAY_REDIRECT_URL', defaultValue: ''),
      webhookUrl: const String.fromEnvironment('HITPAY_WEBHOOK_URL', defaultValue: ''),
    );
  }

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      redirectUrl.trim().isNotEmpty &&
      webhookUrl.trim().isNotEmpty;
}

class HitPayPaymentRequest {
  const HitPayPaymentRequest({
    required this.amount,
    required this.referenceNumber,
    required this.email,
    required this.name,
    required this.purpose,
  });

  final double amount;
  final String referenceNumber;
  final String email;
  final String name;
  final String purpose;
}

class HitPayPaymentResponse {
  const HitPayPaymentResponse({
    required this.id,
    required this.url,
  });

  final String id;
  final String url;
}

class HitPayService {
  HitPayService({
    Dio? dio,
    HitPayConfiguration? configuration,
  }) : _dio = dio ?? Dio(),
       _configuration = configuration ?? HitPayConfiguration.fromEnvironment();

  final Dio _dio;
  final HitPayConfiguration _configuration;

  HitPayConfiguration get configuration => _configuration;

  Future<HitPayPaymentResponse> createPaymentRequest(
    HitPayPaymentRequest request,
  ) async {
    if (!_configuration.isConfigured) {
      throw Exception(
        'HitPay is not configured. Set HITPAY_API_KEY, HITPAY_REDIRECT_URL, and HITPAY_WEBHOOK_URL via --dart-define.',
      );
    }

    final uri = '${_configuration.baseUrl}/payment-requests';

    final response = await _dio.post<Map<String, dynamic>>(
      uri,
      options: Options(
        headers: {
          'X-BUSINESS-API-KEY': _configuration.apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      ),
      data: {
        'amount': request.amount.toStringAsFixed(2),
        'currency': _configuration.currency,
        'email': request.email,
        'name': request.name,
        'purpose': request.purpose,
        'reference_number': request.referenceNumber,
        'redirect_url': _configuration.redirectUrl,
        'webhook': _configuration.webhookUrl,
      },
    );

    final payload = response.data ?? <String, dynamic>{};
    final paymentId = payload['id']?.toString() ?? '';
    final paymentUrl = payload['url']?.toString() ?? '';

    if (paymentId.isEmpty || paymentUrl.isEmpty) {
      throw Exception('HitPay response is missing id or url.');
    }

    return HitPayPaymentResponse(id: paymentId, url: paymentUrl);
  }
}
