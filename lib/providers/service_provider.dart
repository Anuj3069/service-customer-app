import 'package:flutter/material.dart';
import '../models/service.dart';
import '../services/service_api_service.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceApiService _serviceApi = ServiceApiService();
  List<Service> _services = [];
  List<Category> _serviceCategories = [];
  Service? _selectedService;
  bool _isLoading = false;
  String? _error;

  List<Service> get services => _services;
  List<Category> get serviceCategories => _serviceCategories;
  Service? get selectedService => _selectedService;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all services
  Future<void> fetchServices() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _serviceCategories = await _serviceApi.getServiceCategories();
      if (_serviceCategories.isNotEmpty) {
        _services = _serviceCategories
            .expand((category) => category.services)
            .toList();
      } else {
        _services = await _serviceApi.getAllServices();
      }
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
  List<String> get categories => _serviceCategories.isNotEmpty
      ? _serviceCategories.map((category) => category.name).toList()
      : _services
            .where((service) => service.category != null)
            .map((service) => service.category!.name)
            .toSet()
            .toList();

  /// Filter services by category name
  List<Service> servicesByCategory(String categoryName) {
    final category = _serviceCategories.where((c) => c.name == categoryName);
    if (category.isNotEmpty) {
      return category.first.services;
    }
    return _services.where((s) => s.category?.name == categoryName).toList();
  }

  void selectService(Service service) {
    _selectedService = service;
    notifyListeners();
  }
}
