import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/shop_repository.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Cart is empty'));
          }
          final total = items.fold<double>(0, (a, i) => a + i.price * i.qty);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      title: Text(item.title),
                      subtitle: Text('${item.price.toStringAsFixed(0)} ${item.currency} × ${item.qty}'),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          onPressed: () async {
                            await ref.read(shopRepositoryProvider).updateQty(item.productId, item.qty - 1);
                            ref.invalidate(cartProvider);
                          },
                        ),
                        Text('${item.qty}'),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          onPressed: () async {
                            await ref.read(shopRepositoryProvider).updateQty(item.productId, item.qty + 1);
                            ref.invalidate(cartProvider);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () async {
                            await ref.read(shopRepositoryProvider).removeFromCart(item.productId);
                            ref.invalidate(cartProvider);
                          },
                        ),
                      ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  Expanded(child: Text('Total: ${total.toStringAsFixed(0)} EGP', style: theme.textTheme.titleLarge)),
                  FilledButton.icon(
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('Checkout via WhatsApp'),
                    onPressed: () async {
                      final r = await ref.read(shopRepositoryProvider).checkout();
                      if (r.whatsappUrl != null) {
                        await launchUrl(Uri.parse(r.whatsappUrl!), mode: LaunchMode.externalApplication);
                      }
                      ref.invalidate(cartProvider);
                    },
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}
