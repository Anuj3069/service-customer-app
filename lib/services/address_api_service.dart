import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/address.dart';
import 'api_client.dart';

class AddressApiService {
  /// Create a new saved address
  Future<Address> createAddress(Map<String, dynamic> data) async {
    final response = await ApiClient.post(ApiConfig.addresses, data);
    final resData = response['data'];
    if (resData['address'] != null) {
      return Address.fromJson(resData['address']);
    }
    return Address.fromJson(resData);
  }

  /// Get all saved addresses for current user
  Future<List<Address>> getAddresses() async {
    final response = await ApiClient.get(ApiConfig.addresses);
    final resData = response['data'];
    if (resData['addresses'] != null) {
      return (resData['addresses'] as List)
          .map((json) => Address.fromJson(json))
          .toList();
    }
    return [];
  }

  /// Get the default address
  Future<Address?> getDefaultAddress() async {
    try {
      final response = await ApiClient.get(ApiConfig.defaultAddress);
      final resData = response['data'];
      if (resData['address'] != null) {
        return Address.fromJson(resData['address']);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Update a saved address
  Future<Address> updateAddress(String id, Map<String, dynamic> data) async {
    final response = await ApiClient.put(ApiConfig.addressById(id), data);
    final resData = response['data'];
    if (resData['address'] != null) {
      return Address.fromJson(resData['address']);
    }
    return Address.fromJson(resData);
  }

  /// Set an address as default
  Future<Address> setDefaultAddress(String id) async {
    final response =
        await ApiClient.put(ApiConfig.setDefaultAddress(id), {});
    final resData = response['data'];
    if (resData['address'] != null) {
      return Address.fromJson(resData['address']);
    }
    return Address.fromJson(resData);
  }

  /// Delete a saved address
  Future<void> deleteAddress(String id) async {
    await ApiClient.delete(ApiConfig.addressById(id));
  }

  // ── OpenStreetMap Nominatim Search ─────────────────────────

  /// Search for places using OpenStreetMap Nominatim API
  /// Free, no API key needed. Rate limited to 1 req/sec.
  Future<List<PlacePrediction>> searchPlaces(String query) async {
    if (query.trim().length < 3) return [];

    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/search'
      '?q=${Uri.encodeComponent(query)}'
      '&format=json'
      '&addressdetails=1'
      '&limit=8'
      '&countrycodes=in',
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'AirveatCustomerApp/1.0',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List<dynamic> results = json.decode(response.body);
      return results
          .map((json) => PlacePrediction.fromNominatim(json))
          .toList();
    }

    return [];
  }

  /// Reverse geocode coordinates to get address details
  Future<PlacePrediction?> reverseGeocode(
      double latitude, double longitude) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse'
      '?lat=$latitude'
      '&lon=$longitude'
      '&format=json'
      '&addressdetails=1',
    );

    final response = await http.get(uri, headers: {
      'User-Agent': 'AirveatCustomerApp/1.0',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (json != null && json['display_name'] != null) {
        return PlacePrediction.fromNominatim(json);
      }
    }

    return null;
  }
}
