/// Product / cart / review value-objects.
library;

class Product {
  Product({
    required this.id,
    required this.sku,
    required this.titleEn,
    required this.titleAr,
    required this.descriptionEn,
    required this.descriptionAr,
    required this.price,
    required this.currency,
    required this.images,
    required this.category,
    required this.tags,
    required this.stock,
    required this.ratingAvg,
    required this.ratingCount,
    this.vendorWhatsapp = '',
  });

  final String id;
  final String sku;
  final String titleEn;
  final String titleAr;
  final String descriptionEn;
  final String descriptionAr;
  final double price;
  final String currency;
  final List<String> images;
  final String category;
  final List<String> tags;
  final int stock;
  final double ratingAvg;
  final int ratingCount;
  final String vendorWhatsapp;

  String displayTitle(String langCode) =>
      langCode.toLowerCase().startsWith('ar') && titleAr.isNotEmpty ? titleAr : (titleEn.isNotEmpty ? titleEn : titleAr);
  String displayDescription(String langCode) =>
      langCode.toLowerCase().startsWith('ar') && descriptionAr.isNotEmpty ? descriptionAr : descriptionEn;

  factory Product.fromJson(Map<String, dynamic> j) {
    final title = (j['title'] as Map?) ?? const {};
    final desc = (j['description'] as Map?) ?? const {};
    return Product(
      id: (j['_id'] ?? j['id'] ?? '').toString(),
      sku: (j['sku'] ?? '').toString(),
      titleEn: (title['en'] ?? '').toString(),
      titleAr: (title['ar'] ?? '').toString(),
      descriptionEn: (desc['en'] ?? '').toString(),
      descriptionAr: (desc['ar'] ?? '').toString(),
      price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0,
      currency: (j['currency'] ?? 'EGP').toString(),
      images: (j['images'] as List? ?? const []).map((e) => e.toString()).toList(),
      category: (j['category'] ?? 'general').toString(),
      tags: (j['tags'] as List? ?? const []).map((e) => e.toString()).toList(),
      stock: (j['stock'] is num) ? (j['stock'] as num).toInt() : 0,
      ratingAvg: (j['ratingAvg'] is num) ? (j['ratingAvg'] as num).toDouble() : 0,
      ratingCount: (j['ratingCount'] is num) ? (j['ratingCount'] as num).toInt() : 0,
      vendorWhatsapp: (j['vendorWhatsapp'] ?? '').toString(),
    );
  }
}

class CartItem {
  CartItem({required this.productId, required this.qty, required this.title, required this.price, required this.image, this.currency = 'EGP'});
  final String productId;
  final int qty;
  final String title;
  final double price;
  final String image;
  final String currency;

  factory CartItem.fromJson(Map<String, dynamic> j) {
    final title = j['title'];
    final t = title is Map ? (title['en'] ?? title['ar'] ?? '').toString() : (title ?? '').toString();
    return CartItem(
      productId: (j['productId'] ?? '').toString(),
      qty: (j['qty'] ?? 1) is int ? j['qty'] : 1,
      title: t,
      price: (j['price'] is num) ? (j['price'] as num).toDouble() : 0,
      image: (j['image'] ?? '').toString(),
      currency: (j['currency'] ?? 'EGP').toString(),
    );
  }
}

class Review {
  Review({required this.id, required this.userName, required this.rating, required this.comment, required this.createdAt});
  final String id;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id: (j['_id'] ?? j['id'] ?? '').toString(),
        userName: (j['userName'] ?? 'User').toString(),
        rating: (j['rating'] ?? 0) is int ? j['rating'] : 0,
        comment: (j['comment'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['createdAt'] ?? '').toString()) ?? DateTime.now(),
      );
}
