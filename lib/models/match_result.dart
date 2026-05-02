class MatchResult {
  final MatchProvider provider;
  final MatchService service;
  final double price;
  final int estimatedDuration;
  final String date;
  final String slot;

  MatchResult({
    required this.provider,
    required this.service,
    required this.price,
    required this.estimatedDuration,
    required this.date,
    required this.slot,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) {
    return MatchResult(
      provider: MatchProvider.fromJson(json['provider']),
      service: MatchService.fromJson(json['service']),
      price: (json['price'] ?? 0).toDouble(),
      estimatedDuration: json['estimatedDuration'] ?? 0,
      date: json['date'] ?? '',
      slot: json['slot'] ?? '',
    );
  }
}

class MatchProvider {
  final String id;
  final String name;
  final double rating;
  final int totalJobs;
  final bool isVerified;

  MatchProvider({
    required this.id,
    required this.name,
    required this.rating,
    required this.totalJobs,
    required this.isVerified,
  });

  factory MatchProvider.fromJson(Map<String, dynamic> json) {
    return MatchProvider(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Provider',
      rating: (json['rating'] ?? 0).toDouble(),
      totalJobs: json['totalJobs'] ?? 0,
      isVerified: json['isVerified'] ?? false,
    );
  }
}

class MatchService {
  final String id;
  final String name;

  MatchService({required this.id, required this.name});

  factory MatchService.fromJson(Map<String, dynamic> json) {
    return MatchService(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
