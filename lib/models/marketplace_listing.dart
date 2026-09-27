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
  };

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final sellerName =
        json['sellerName'] as String? ?? json['seller'] as String?;
    return MarketplaceListing(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      condition: json['condition'] as String? ?? '',
      sellerName: sellerName,
      location: json['location'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>? ?? []).whereType<String>().toList(),
      imageUrl: json['imageUrl'] as String?,
      matchScore: (json['matchScore'] as num?)?.toDouble(),
    );
  }
}
