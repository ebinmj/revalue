class MarketplaceListing {
  const MarketplaceListing({
    this.id = '',
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    this.currency = 'INR',
    required this.condition,
    String? sellerName,
    String? seller,
    this.location = '',
    this.tags = const [],
    this.imageUrl,
    this.matchScore,
    this.sellerId,
    this.status = 'available',
    this.createdAt,
  }) : sellerName = sellerName ?? seller ?? '';

  final String id;
  final String title;
  final String description;
  final String category;
  final double price;
  final String currency;
  final String condition;
  final String sellerName;
  final String location;
  final List<String> tags;
  final String? imageUrl;
  final double? matchScore;
  final String? sellerId;
  final String status;
  final DateTime? createdAt;

  String get seller => sellerName;

  MarketplaceListing copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? price,
    String? currency,
    String? condition,
    String? sellerName,
    String? seller,
    String? location,
    List<String>? tags,
    String? imageUrl,
    double? matchScore,
    String? sellerId,
    String? status,
    DateTime? createdAt,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      condition: condition ?? this.condition,
      sellerName: sellerName ?? this.sellerName,
      seller: seller ?? this.sellerName,
      location: location ?? this.location,
      tags: tags ?? this.tags,
      imageUrl: imageUrl ?? this.imageUrl,
      matchScore: matchScore ?? this.matchScore,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'category': category,
    'price': price,
    'currency': currency,
    'condition': condition,
    'sellerName': sellerName,
    'location': location,
    'tags': List<String>.from(tags),
    'imageUrl': imageUrl,
    'matchScore': matchScore,
    'seller_id': sellerId,
    'status': status,
    'created_at': createdAt?.toIso8601String(),
  };

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'];
    final profileName = profile is Map<String, dynamic>
        ? profile['name'] as String?
        : profile is List && profile.isNotEmpty
        ? (profile.first as Map<String, dynamic>)['name'] as String?
        : null;
    final sellerName =
        json['seller_name'] as String? ??
        json['sellerName'] as String? ??
        json['seller'] as String? ??
        profileName;
    final price = json['price'];
    return MarketplaceListing(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: price is num ? price.toDouble() : double.tryParse('$price') ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      condition: json['condition'] as String? ?? '',
      sellerName: sellerName,
      location: json['location'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      imageUrl: json['image_url'] as String? ?? json['imageUrl'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble(),
      sellerId: json['seller_id'] as String?,
      status: json['status'] as String? ?? 'available',
      createdAt: DateTime.tryParse(
        json['created_at'] as String? ?? json['createdAt'] as String? ?? '',
      ),
    );
  }
}
