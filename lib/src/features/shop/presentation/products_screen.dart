import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/shop_repository.dart';
import '../domain/product_models.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String? _category;
  static const _cats = ['all', 'hearing', 'deaf', 'blind', 'low-vision', 'learning', 'hardware'];

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(_category == 'all' ? null : _category));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_rounded),
            tooltip: 'Cart',
            onPressed: () => context.push('/shop/cart'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final c = _cats[i];
                final selected = (c == 'all' && _category == null) || c == _category;
                return ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c == 'all' ? null : c),
                );
              },
            ),
          ),
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Failed to load: $e')),
              data: (products) {
                if (products.isEmpty) {
                  return const Center(child: Text('No products yet — run server seed script.'));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.66,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemBuilder: (context, i) => _ProductCard(p: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.p});
  final Product p;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/shop/product/${p.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: p.images.isEmpty
                  ? Container(color: theme.colorScheme.surfaceContainer, child: const Icon(Icons.image_rounded, size: 48))
                  : CachedNetworkImage(imageUrl: p.images.first, fit: BoxFit.cover, placeholder: (c, _) => const ColoredBox(color: Colors.black12), errorWidget: (_, __, ___) => const Icon(Icons.broken_image_rounded)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.displayTitle('ar'), maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                  Text('${p.price.toStringAsFixed(0)} ${p.currency}', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                  Row(children: [
                    Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                    Text(' ${p.ratingAvg.toStringAsFixed(1)} (${p.ratingCount})', style: theme.textTheme.bodySmall),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
