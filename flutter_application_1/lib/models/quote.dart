class Quote {
  final String? id;
  final String text;
  final String author;
  final String category;
  final bool isFavorite;
  final int createdAt;

  Quote({
    this.id,
    required this.text,
    required this.author,
    required this.category,
    this.isFavorite = false,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'author': author,
      'category': category,
      'isFavorite': isFavorite,
      'createdAt': createdAt,
    };
  }

  // Create from JSON
  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String?,
      text: json['text'] as String,
      author: json['author'] as String,
      category: json['category'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      createdAt: json['createdAt'] as int?,
    );
  }

  // Copy with
  Quote copyWith({
    String? id,
    String? text,
    String? author,
    String? category,
    bool? isFavorite,
    int? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      text: text ?? this.text,
      author: author ?? this.author,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
