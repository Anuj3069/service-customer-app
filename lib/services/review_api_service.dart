import '../config/api_config.dart';
import 'api_client.dart';

class ReviewApiService {
  /// Create a review for a completed booking
  Future<Map<String, dynamic>> createReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'bookingId': bookingId,
      'rating': rating,
    };
    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }

    final response = await ApiClient.post(ApiConfig.reviews, body);
    return response['data'];
  }
}
