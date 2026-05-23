class NearbyWorker {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final double rating;
  final int totalJobs;
  final int totalReviews;
  final bool isVerified;
  final List<double> coordinates; // [lng, lat]
  final double distance; // in km
  final List<String> skills;

  NearbyWorker({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.rating,
    required this.totalJobs,
    required this.totalReviews,
    required this.isVerified,
    required this.coordinates,
    required this.distance,
    required this.skills,
  });

  factory NearbyWorker.fromJson(Map<String, dynamic> json) {
    return NearbyWorker(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      name: json['name'] ?? 'Provider',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalJobs: json['totalJobs'] ?? 0,
      totalReviews: json['totalReviews'] ?? 0,
      isVerified: json['isVerified'] ?? false,
      coordinates: List<double>.from((json['coordinates'] as List?)?.map((e) => (e as num).toDouble()) ?? [0.0, 0.0]),
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  double get latitude => coordinates.length > 1 ? coordinates[1] : 0.0;
  double get longitude => coordinates.isNotEmpty ? coordinates[0] : 0.0;
}
