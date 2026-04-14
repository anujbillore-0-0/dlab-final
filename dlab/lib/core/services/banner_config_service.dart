import 'package:supabase_flutter/supabase_flutter.dart';

class BannerConfigService {
  BannerConfigService._();

  static final BannerConfigService instance = BannerConfigService._();

  Future<List<String>?> getBannerUrls(String category) async {
    try {
      final row =
          await Supabase.instance.client
              .from('banners')
              .select('category, image_urls, image_url, links, urls')
              .eq('category', category)
              .maybeSingle();

      return _extractUrls(row);
    } catch (_) {
      return null;
    }
  }

  List<String>? _extractUrls(Map<String, dynamic>? row) {
    if (row == null) return null;

    final dynamic imageUrls = row['image_urls'];
    final dynamic imageUrl = row['image_url'];
    final dynamic links = row['links'];
    final dynamic urls = row['urls'];

    final values = <String>[];

    void collect(dynamic value) {
      if (value is String) {
        values.add(value);
      } else if (value is List) {
        for (final entry in value) {
          if (entry is String) values.add(entry);
        }
      }
    }

    collect(imageUrls);
    collect(imageUrl);
    collect(links);
    collect(urls);

    final parsed = <String>[];
    for (final value in values) {
      parsed.addAll(value.split(','));
    }

    final cleaned =
        parsed
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .where((value) {
              final uri = Uri.tryParse(value);
              return uri != null &&
                  uri.hasScheme &&
                  (uri.scheme == 'http' || uri.scheme == 'https');
            })
            .toList();

    if (cleaned.isEmpty) return null;
    return cleaned;
  }
}
