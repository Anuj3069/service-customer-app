import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_api_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceApiService _serviceApi = ServiceApiService();
  List<Service> _services = [];
  Service? _selectedService;
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  Service? get selectedService => _selectedService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all services
  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _services = await _serviceApi.getAllServices();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch a single service
  Future<void> fetchServiceById(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedService = await _serviceApi.getServiceById(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get unique categories from loaded services
  List<String> get categories {
    final cats = <String>{};
    for (var s in _services) {
      if (s.category != null) {
        cats.add(s.category!.name);
      }
    }
    return cats.toList();
  }

  /// Filter services by category name
  List<Service> servicesByCategory(String categoryName) {
    return _services
        .where((s) => s.category?.name == categoryName)
        .toList();
  }

  void selectService(Service service) {
    _selectedService = service;
    notifyListeners();
  }
}
