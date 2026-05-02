import '../config/api_config.dart';
import '../models/match_result.dart';
import 'api_client.dart';

class MatchApiService {
  /// Find a matching provider for a service request
  Future<MatchResult> findMatch({
    required String serviceId,
    required String date,
    required String slot,
  }) async {
    final response = await ApiClient.post(ApiConfig.match, {
      'serviceId': serviceId,
      'date': date,
      'slot': slot,
    });

    return MatchResult.fromJson(response['data']['match']);
  }
}
