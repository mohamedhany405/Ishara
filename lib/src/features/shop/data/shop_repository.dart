/// Network layer for the Shop feature.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_provider.dart';
import '../domain/product_models.dart';

class ShopRepository {
  ShopRepository(this._api);
  final ApiClient _api;

  Future<List<Product>> products({String? category, String? query}) async {
    final r = await _api.get('/api/products', queryParameters: {
      if (category != null && category.isNotEmpty) 'category': category,
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final list = (r.data['products'] as List? ?? const [])
        .map((e) => Product.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }

  Future<Product?> productById(String id) async {
    try {
      final r = await _api.get('/api/products/$id');
      return Product.fromJson(Map<String, dynamic>.from(r.data['product'] as Map));
    } catch (_) {
      return null;
    }
  }

  Future<List<Review>> reviewsFor(String productId) async {
    try {
      final r = await _api.get('/api/reviews/product/$productId');
      return (r.data['reviews'] as List? ?? const [])
          .map((e) => Review.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> postReview(String productId, int rating, String comment) async {
    try {
      await _api.post('/api/reviews/product/$productId', data: {'rating': rating, 'comment': comment});
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<CartItem>> cart() async {
    try {
      final r = await _api.get('/api/cart');
      return (r.data['items'] as List? ?? const [])
          .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<CartItem>> addToCart(String productId, {int qty = 1}) async {
    final r = await _api.post('/api/cart', data: {'productId': productId, 'qty': qty});
    return (r.data['items'] as List? ?? const [])
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<CartItem>> updateQty(String productId, int qty) async {
    final r = await _api.put('/api/cart/$productId', data: {'qty': qty});
    return (r.data['items'] as List? ?? const [])
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<CartItem>> removeFromCart(String productId) async {
    final r = await _api.delete('/api/cart/$productId');
    return (r.data['items'] as List? ?? const [])
        .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({String? whatsappUrl, String? orderId})> checkout({String shippingAddress = ''}) async {
    try {
      final r = await _api.post('/api/orders/checkout', data: {'shippingAddress': shippingAddress});
      final whatsapp = r.data['whatsappUrl']?.toString();
      final order = r.data['order'] as Map?;
      return (whatsappUrl: whatsapp, orderId: order?['_id']?.toString());
    } catch (_) {
      return (whatsappUrl: null, orderId: null);
    }
  }
}

final shopRepositoryProvider = Provider<ShopRepository>((ref) {
  return ShopRepository(ref.watch(apiClientProvider));
});

final productsProvider = FutureProvider.family<List<Product>, String?>((ref, category) async {
  return ref.watch(shopRepositoryProvider).products(category: category);
});

final cartProvider = FutureProvider<List<CartItem>>((ref) async {
  return ref.watch(shopRepositoryProvider).cart();
});

final reviewsProvider = FutureProvider.family<List<Review>, String>((ref, productId) async {
  return ref.watch(shopRepositoryProvider).reviewsFor(productId);
});
