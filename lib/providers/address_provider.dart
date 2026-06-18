import 'dart:async';
import 'package:flutter/material.dart';
import '../models/address.dart';
import '../services/address_api_service.dart';
import '../utils/location_helper.dart';

class AddressProvider extends ChangeNotifier {
  final AddressApiService _addressApi = AddressApiService();

  List<Address> _addresses = [];
  Address? _defaultAddress;
  Address? _selectedAddress; // Currently selected for booking
  List<PlacePrediction> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  String? _error;
  String? _successMessage;

  // Debounce timer for search
  Timer? _searchDebounce;

  // ── Getters ──────────────────────────────────────────
  List<Address> get addresses => _addresses;
  Address? get defaultAddress => _defaultAddress;
  Address? get selectedAddress => _selectedAddress;
  List<PlacePrediction> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get error => _error;
  String? get successMessage => _successMessage;
  bool get hasAddresses => _addresses.isNotEmpty;

  // ── Fetch Addresses ──────────────────────────────────

  /// Fetch all saved addresses from the backend
  Future<void> fetchAddresses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _addressApi.getAddresses();
      if (_addresses.isEmpty) {
        _defaultAddress = null;
      } else {
        _defaultAddress = _addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _addresses.first,
        );
      }

      // Auto-select default if nothing selected
      if (_selectedAddress == null && _defaultAddress != null) {
        _selectedAddress = _defaultAddress;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch only the default address
  Future<void> fetchDefaultAddress() async {
    try {
      _defaultAddress = await _addressApi.getDefaultAddress();
      if (_selectedAddress == null && _defaultAddress != null) {
        _selectedAddress = _defaultAddress;
      }
      notifyListeners();
    } catch (_) {}
  }

  // ── CRUD ─────────────────────────────────────────────

  /// Create a new saved address
  Future<bool> createAddress(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final address = await _addressApi.createAddress(data);
      _addresses.insert(0, address);

      // If it's the first address or marked default, update
      if (address.isDefault || _addresses.length == 1) {
        _defaultAddress = address;
        _selectedAddress ??= address;
      }

      _successMessage = 'Address saved successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update an existing address
  Future<bool> updateAddress(String id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _addressApi.updateAddress(id, data);
      _addresses = _addresses
          .map((a) => a.id == id ? updated : a)
          .toList();

      if (updated.isDefault) {
        _defaultAddress = updated;
        // Unmark other defaults in local state
        _addresses = _addresses.map((a) {
          if (a.id != id && a.isDefault) {
            return a.copyWith(isDefault: false);
          }
          return a;
        }).toList();
      }

      if (_selectedAddress?.id == id) {
        _selectedAddress = updated;
      }

      _successMessage = 'Address updated successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Set an address as default
  Future<bool> setDefault(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _addressApi.setDefaultAddress(id);
      _defaultAddress = updated;

      // Update local state
      _addresses = _addresses.map((a) {
        if (a.id == id) return updated;
        if (a.isDefault) return a.copyWith(isDefault: false);
        return a;
      }).toList();

      _successMessage = 'Default address updated!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressApi.deleteAddress(id);
      _addresses.removeWhere((a) => a.id == id);

      // If we deleted the default, fetch updated list
      if (_defaultAddress?.id == id) {
        _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }

      if (_selectedAddress?.id == id) {
        _selectedAddress = _defaultAddress;
      }

      _successMessage = 'Address deleted successfully!';
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Address Selection (for booking) ──────────────────

  /// Select an address for the current booking session
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Select address by creating a temporary one from current GPS location
  Future<bool> selectCurrentLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final pos = await LocationHelper.getCurrentLocation();
      if (pos == null) {
        _error = 'Could not get your current location. Please enable GPS.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Reverse geocode to get address string
      final prediction = await _addressApi.reverseGeocode(
        pos.latitude,
        pos.longitude,
      );

      _selectedAddress = Address(
        id: 'current_location',
        userId: '',
        label: 'other',
        customLabel: 'Current Location',
        fullAddress: prediction?.displayName ?? 'Current Location',
        coordinates: [pos.longitude, pos.latitude],
        isDefault: false,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to get current location: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ── Search (OpenStreetMap Nominatim) ──────────────────

  /// Search for places with debouncing (300ms)
  void searchPlaces(String query) {
    _searchDebounce?.cancel();

    if (query.trim().length < 3) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        _searchResults = await _addressApi.searchPlaces(query);
        _isSearching = false;
        notifyListeners();
      } catch (e) {
        _searchResults = [];
        _isSearching = false;
        notifyListeners();
      }
    });
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
    _searchDebounce?.cancel();
    notifyListeners();
  }

  // ── Utility ──────────────────────────────────────────

  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
