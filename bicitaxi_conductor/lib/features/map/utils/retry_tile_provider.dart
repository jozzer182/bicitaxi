import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/retry.dart';

/// Custom network tile provider with exponential backoff retry.
/// Retries failed tile requests with increasing delays: 1s → 3s → 6s → 10s.
class RetryTileProvider extends NetworkTileProvider {
  RetryTileProvider({super.headers})
    : super(
        httpClient: RetryClient(
          http.Client(),
          retries: 4,
          delay: _exponentialBackoff,
          when: (response) => response.statusCode >= 500,
          whenError: (error, stackTrace) => true,
        ),
      );

  /// Exponential backoff delay: 1s, 3s, 6s, 10s
  static Duration _exponentialBackoff(int retryCount) {
    const delays = [1, 3, 6, 10];
    final index = retryCount.clamp(0, delays.length - 1);
    return Duration(seconds: delays[index]);
  }
}
