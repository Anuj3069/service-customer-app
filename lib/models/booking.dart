class Booking {
  final String id;
  final String userId;
  final String? providerId;
  final String serviceId;
  final String? date;
  final String? slot;
  final String status;
  final double price;
  final String type; // 'SCHEDULED' or 'INSTANT'
  final String? expiresAt;
  final String? requestedAt;
  final String? acceptedAt;
  final String? completedAt;
  final String? cancelledAt;
  final String? rejectedAt;
  final String? cancellationReason;
  final String createdAt;
  final Map<String, dynamic>? serviceDetails;
  final Map<String, dynamic>? providerDetails;

  Booking({
    required this.id,
    required this.userId,
    this.providerId,
    required this.serviceId,
    this.date,
    this.slot,
    required this.status,
    required this.price,
    this.type = 'SCHEDULED',
    this.expiresAt,
    this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.cancelledAt,
    this.rejectedAt,
    this.cancellationReason,
    required this.createdAt,
    this.serviceDetails,
    this.providerDetails,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? ''
          : json['userId'] ?? '',
      providerId: json['providerId'] is Map
          ? json['providerId']['_id'] ?? ''
          : json['providerId'] ?? '',
      serviceId: json['serviceId'] is Map
          ? json['serviceId']['_id'] ?? ''
          : json['serviceId'] ?? '',
      date: json['date'] ?? '',
      slot: json['slot'] ?? '',
      status: json['status'] ?? 'pending',
      price: (json['price'] ?? 0).toDouble(),
      type: json['type'] ?? 'SCHEDULED',
      expiresAt: json['expiresAt'],
      requestedAt: json['requestedAt'],
      acceptedAt: json['acceptedAt'],
      completedAt: json['completedAt'],
      cancelledAt: json['cancelledAt'],
      rejectedAt: json['rejectedAt'],
      cancellationReason: json['cancellationReason'],
      createdAt: json['createdAt'] ?? '',
      serviceDetails: json['serviceId'] is Map ? json['serviceId'] : null,
      providerDetails: json['providerId'] is Map ? json['providerId'] : null,
    );
  }

  bool get isInstant => type == 'INSTANT';
  bool get isRequested => status == 'requested';
  bool get isExpired => status == 'expired';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';

  String get serviceName => serviceDetails?['name'] ?? 'Service';
  String get providerName {
    if (providerDetails?['userId'] is Map) {
      return providerDetails!['userId']['name'] ?? 'Provider';
    }
    return 'Provider';
  }
}
