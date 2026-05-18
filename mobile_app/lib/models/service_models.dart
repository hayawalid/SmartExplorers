/// Service Models for SmartExplorers
/// Represents service offerings from providers

class ServiceAvailability {
  final List<String> days;
  final String? hoursStart;
  final String? hoursEnd;

  ServiceAvailability({this.days = const [], this.hoursStart, this.hoursEnd});

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      days: List<String>.from(json['days'] ?? []),
      hoursStart: json['hours_start'],
      hoursEnd: json['hours_end'],
    );
  }

  Map<String, dynamic> toJson() => {
    'days': days,
    'hours_start': hoursStart,
    'hours_end': hoursEnd,
  };
}

class Service {
  final String? id;
  final String providerId;
  final String serviceType;
  final String serviceName;
  final String? description;
  final List<String> tags;
  final List<String> clusterKeywords;
  final double? priceMin;
  final double? priceMax;
  final String currency;
  final ServiceAvailability availability;
  final double rating;
  final int reviewsCount;
  final int bookingsCount;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Optional fields for display
  final double? distanceKm;
  final String? providerName;
  final String? providerEmail;
  final Map<String, dynamic>? provider;

  Service({
    this.id,
    required this.providerId,
    required this.serviceType,
    required this.serviceName,
    this.description,
    this.tags = const [],
    this.clusterKeywords = const [],
    this.priceMin,
    this.priceMax,
    this.currency = 'EGP',
    ServiceAvailability? availability,
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.bookingsCount = 0,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.distanceKm,
    this.providerName,
    this.providerEmail,
    this.provider,
  }) : availability = availability ?? ServiceAvailability();

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['_id'],
      providerId: json['provider_id'],
      serviceType: json['service_type'],
      serviceName: json['service_name'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      clusterKeywords: List<String>.from(json['cluster_keywords'] ?? []),
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
      currency: json['currency'] ?? 'EGP',
      availability:
          json['availability'] != null
              ? ServiceAvailability.fromJson(
                json['availability'] as Map<String, dynamic>,
              )
              : ServiceAvailability(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewsCount: json['reviews_count'] as int? ?? 0,
      bookingsCount: json['bookings_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'].toString())
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'].toString())
              : null,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      providerName: json['provider_name'],
      providerEmail: json['provider_email'],
      provider: json['provider'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'provider_id': providerId,
    'service_type': serviceType,
    'service_name': serviceName,
    'description': description,
    'tags': tags,
    'cluster_keywords': clusterKeywords,
    'price_min': priceMin,
    'price_max': priceMax,
    'currency': currency,
    'availability': availability.toJson(),
    'rating': rating,
    'reviews_count': reviewsCount,
    'bookings_count': bookingsCount,
    'is_active': isActive,
  };

  String get priceRange {
    if (priceMin == null || priceMax == null) return 'Contact for pricing';
    return '$currency ${priceMin?.toStringAsFixed(0)}-${priceMax?.toStringAsFixed(0)}';
  }

  String get availabilityText {
    if (availability.days.isEmpty) return 'Availability to be confirmed';
    return '${availability.days.join(", ")} ${availability.hoursStart != null ? "from ${availability.hoursStart}" : ""}';
  }

  String get ratingText {
    if (rating == 0) return 'No ratings yet';
    return '$rating★ (${reviewsCount} reviews)';
  }
}

class ServiceFilter {
  final String? searchQuery;
  final String? serviceType;
  final List<String> tags;
  final double? minRating;
  final double? latitude;
  final double? longitude;
  final double radiusKm;
  final int? clusterId;

  ServiceFilter({
    this.searchQuery,
    this.serviceType,
    this.tags = const [],
    this.minRating,
    this.latitude,
    this.longitude,
    this.radiusKm = 50,
    this.clusterId,
  });

  bool get hasLocationFilter => latitude != null && longitude != null;

  ServiceFilter copyWith({
    String? searchQuery,
    String? serviceType,
    List<String>? tags,
    double? minRating,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int? clusterId,
  }) {
    return ServiceFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      serviceType: serviceType ?? this.serviceType,
      tags: tags ?? this.tags,
      minRating: minRating ?? this.minRating,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
      clusterId: clusterId ?? this.clusterId,
    );
  }
}

class ServiceProvider {
  final String id;
  final String name;
  final String email;
  final double rating;
  final int reviewCount;
  final int completedTours;
  final bool verified;
  final String? bio;
  final List<String> languages;
  final Map<String, dynamic>? location;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.email,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.completedTours = 0,
    this.verified = false,
    this.bio,
    this.languages = const [],
    this.location,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['review_count'] as int? ?? 0,
      completedTours: json['completed_tours'] as int? ?? 0,
      verified: json['verified'] as bool? ?? false,
      bio: json['bio'],
      languages: List<String>.from(json['languages'] ?? []),
      location: json['location'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'rating': rating,
    'review_count': reviewCount,
    'completed_tours': completedTours,
    'verified': verified,
    'bio': bio,
    'languages': languages,
    'location': location,
  };
}
