class Address {
  final String id;
  final String userId;
  final String label; // 'home', 'work', 'other'
  final String? customLabel;
  final String fullAddress;
  final String? addressLine2;
  final String? city;
  final String? state;
  final String? pincode;
  final List<double> coordinates; // [longitude, latitude]
  final String? placeId;
  final bool isDefault;
  final String? createdAt;

  Address({
    required this.id,
    required this.userId,
    this.label = 'other',
    this.customLabel,
    required this.fullAddress,
    this.addressLine2,
    this.city,
    this.state,
    this.pincode,
    required this.coordinates,
    this.placeId,
    this.isDefault = false,
    this.createdAt,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    List<double> coords = [0.0, 0.0];
    if (json['location'] != null && json['location']['coordinates'] is List) {
      coords = List<double>.from(
        (json['location']['coordinates'] as List).map(
          (x) => (x as num).toDouble(),
        ),
      );
    }

    return Address(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? ''
          : json['userId'] ?? '',
      label: json['label'] ?? 'other',
      customLabel: json['customLabel'],
      fullAddress: json['fullAddress'] ?? '',
      addressLine2: json['addressLine2'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      coordinates: coords,
      placeId: json['placeId'],
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    if (customLabel != null) 'customLabel': customLabel,
    'fullAddress': fullAddress,
    if (addressLine2 != null && addressLine2!.isNotEmpty)
      'addressLine2': addressLine2,
    if (city != null && city!.isNotEmpty) 'city': city,
    if (state != null && state!.isNotEmpty) 'state': state,
    if (pincode != null && pincode!.isNotEmpty) 'pincode': pincode,
    'location': {'type': 'Point', 'coordinates': coordinates},
    if (placeId != null && placeId!.isNotEmpty) 'placeId': placeId,
    'isDefault': isDefault,
  };

  /// Convert to the customerLocation format expected by the booking API
  Map<String, dynamic> toCustomerLocation() {
    final isPersistedAddress = RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id);

    return {
      'coordinates': coordinates,
      'address': displayName,
      if (isPersistedAddress) 'addressId': id,
      'fullAddress': fullAddress,
      if (addressLine2 != null && addressLine2!.isNotEmpty)
        'addressLine2': addressLine2,
      'label': label,
    };
  }

  /// Display label (e.g., "Home", "Work", or custom label)
  String get displayLabel {
    if (label == 'other' && customLabel != null && customLabel!.isNotEmpty) {
      return customLabel!;
    }
    return label[0].toUpperCase() + label.substring(1);
  }

  /// Display name — label + short address
  String get displayName {
    return '$displayLabel • $shortAddress';
  }

  /// Short version of the address (first line only)
  String get shortAddress {
    final parts = fullAddress.split(',');
    if (parts.length > 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return fullAddress;
  }

  /// Latitude (coordinates[1])
  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;

  /// Longitude (coordinates[0])
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;

  /// Label icon
  String get labelEmoji {
    switch (label) {
      case 'home':
        return '🏠';
      case 'work':
        return '💼';
      default:
        return '📍';
    }
  }

  Address copyWith({
    String? id,
    String? userId,
    String? label,
    String? customLabel,
    String? fullAddress,
    String? addressLine2,
    String? city,
    String? state,
    String? pincode,
    List<double>? coordinates,
    String? placeId,
    bool? isDefault,
    String? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      label: label ?? this.label,
      customLabel: customLabel ?? this.customLabel,
      fullAddress: fullAddress ?? this.fullAddress,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      coordinates: coordinates ?? this.coordinates,
      placeId: placeId ?? this.placeId,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Represents a place prediction from OpenStreetMap Nominatim search
class PlacePrediction {
  final String placeId;
  final String displayName;
  final String? city;
  final String? state;
  final String? postcode;
  final double latitude;
  final double longitude;

  PlacePrediction({
    required this.placeId,
    required this.displayName,
    this.city,
    this.state,
    this.postcode,
    required this.latitude,
    required this.longitude,
  });

  factory PlacePrediction.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};

    return PlacePrediction(
      placeId: json['place_id']?.toString() ?? '',
      displayName: json['display_name'] ?? '',
      city:
          address['city'] ??
          address['town'] ??
          address['village'] ??
          address['suburb'],
      state: address['state'],
      postcode: address['postcode'],
      latitude: double.tryParse(json['lat']?.toString() ?? '') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '') ?? 0.0,
    );
  }

  /// Short display (first two comma-separated parts)
  String get shortName {
    final parts = displayName.split(',');
    if (parts.length > 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return displayName;
  }

  /// Sub-text (remaining parts after first two)
  String get subText {
    final parts = displayName.split(',');
    if (parts.length > 2) {
      return parts.sublist(2).map((e) => e.trim()).join(', ');
    }
    return '';
  }
}
