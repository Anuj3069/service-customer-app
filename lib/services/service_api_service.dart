import '../config/api_config.dart';
import '../models/service.dart';
import 'api_client.dart';

class ServiceApiService {
  /// Get all services
  Future<List<Service>> getAllServices() async {
    final response = await ApiClient.get(ApiConfig.services);
    final data = response['data'];

    if (data is Map && data['services'] != null) {
      return (data['services'] as List)
          .map((json) => Service.fromJson(json))
          .toList();
    }
    if (data is Map && data['categories'] != null) {
      // If response groups by categories
      final List<Service> services = [];
      for (var cat in data['categories']) {
        if (cat['services'] != null) {
          for (var s in cat['services']) {
            services.add(Service.fromJson(s));
          }
        }
      }
      return services;
    }
    if (data is List) {
      return data.map((json) => Service.fromJson(json)).toList();
    }
    return [];
  }

  /// Get service by ID
  Future<Service> getServiceById(String id) async {
    final response = await ApiClient.get(ApiConfig.serviceById(id));
    final data = response['data'];

    if (data is Map && data['service'] != null) {
      return Service.fromJson(data['service']);
    }
    return Service.fromJson(data);
  }
}
