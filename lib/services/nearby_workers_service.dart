import '../config/api_config.dart';
import '../models/nearby_worker.dart';
import 'api_client.dart';

class NearbyWorkersService {
  /// Fetch active workers near the customer's coordinates for a specific category
  Future<List<NearbyWorker>> getNearbyWorkers({
    required String categoryId,
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
  }) async {
    final endpoint = '${ApiConfig.nearbyWorkers}?categoryId=$categoryId&lat=$latitude&lng=$longitude&radius=$radiusKm';
    final response = await ApiClient.get(endpoint);
    
    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return [];
    
    final workersList = data['workers'] as List?;
    if (workersList == null) return [];
    
    return workersList.map((json) => NearbyWorker.fromJson(json)).toList();
  }
}
