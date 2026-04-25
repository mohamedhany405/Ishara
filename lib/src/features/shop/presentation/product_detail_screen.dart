import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../data/shop_repository.dart';
import '../domain/product_models.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});
  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  Product? _product;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await ref.read(shopRepositoryProvider).productById(widget.productId);
    if (!mounted) return;
    setState(() {
      _product = p;
      _loading = false;
    });
  }

  Future<void> _addToCart() async {
    final repo = ref.read(shopRepositoryProvider);
    await repo.addToCart(widget.productId);
    ref.invalidate(cartProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
  }

  Future<void> _writeReview() async {
    int rating = 5;
    final ctrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Write review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(builder: (context, setS) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded, color: Colors.amber),
                    onPressed: () => setS(() => rating = i + 1),
                  );
                }),
              );
            }),
            TextField(controller: ctrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Comment')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Submit')),
        ],
      ),
    );
    if (saved == true) {
      await ref.read(shopRepositoryProvider).postReview(widget.productId, rating, ctrl.text.trim());
      ref.invalidate(reviewsProvider(widget.productId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final p = _product;
    if (p == null) return const Scaffold(body: Center(child: Text('Not found')));
    final reviewsAsync = ref.watch(reviewsProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: Text(p.displayTitle('ar')),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => Share.share('${p.displayTitle("ar")} — ${p.price.toStringAsFixed(0)} ${p.currency}\n${p.images.firstOrNull ?? ""}'),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text('${p.price.toStringAsFixed(0)} ${p.currency}', style: theme.textTheme.headlineSmall)),
              FilledButton.icon(onPressed: _addToCart, icon: const Icon(Icons.add_shopping_cart_rounded), label: const Text('Add to cart')),
            ],
          ),
        ),
      ),
      body: ListView(
        children: [
          if (p.images.isNotEmpty)
            AspectRatio(
              aspectRatio: 1.2,
              child: CachedNetworkImage(imageUrl: p.images.first, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.displayTitle('ar'), style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                  Text(' ${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})'),
                ]),
                const SizedBox(height: 12),
                Text(p.displayDescription('ar')),
                const SizedBox(height: 24),
                Row(children: [
                  Text('Reviews', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _writeReview,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Write a review'),
                  ),
                ]),
                reviewsAsync.when(
                  loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
                  error: (e, _) => Text('Failed: $e'),
                  data: (reviews) {
                    if (reviews.isEmpty) {
                      return const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('No reviews yet'));
                    }
                    return Column(
                      children: reviews.map((r) {
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Text(r.userName.isEmpty ? '?' : r.userName.characters.first)),
                            title: Row(children: [
                              Text(r.userName),
                              const Spacer(),
                              Row(children: List.generate(5, (i) => Icon(i < r.rating ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: Colors.amber))),
                            ]),
                            subtitle: Text(r.comment),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
