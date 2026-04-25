import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/auth_provider.dart';

final _socialProvider = FutureProvider<Map<String, String>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final r = await api.get('/api/social');
    final m = (r.data['socialLinks'] as Map?)?.cast<String, dynamic>() ?? const {};
    return m.map((k, v) => MapEntry(k, (v ?? '').toString()));
  } catch (_) {
    return const {};
  }
});

class SocialLinksScreen extends ConsumerStatefulWidget {
  const SocialLinksScreen({super.key});
  @override
  ConsumerState<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends ConsumerState<SocialLinksScreen> {
  final Map<String, TextEditingController> _ctrls = {
    'instagram': TextEditingController(),
    'facebook': TextEditingController(),
    'twitter': TextEditingController(),
    'tiktok': TextEditingController(),
    'whatsapp': TextEditingController(),
    'youtube': TextEditingController(),
  };
  bool _hydrated = false;

  static const _icons = {
    'instagram': Icons.camera_alt_rounded,
    'facebook': Icons.facebook_rounded,
    'twitter': Icons.alternate_email_rounded,
    'tiktok': Icons.music_note_rounded,
    'whatsapp': Icons.chat_rounded,
    'youtube': Icons.play_circle_rounded,
  };

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final api = ref.read(apiClientProvider);
    final body = _ctrls.map((k, v) => MapEntry(k, v.text.trim()));
    try {
      await api.put('/api/social', data: body);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
      }
      ref.invalidate(_socialProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_socialProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Social Links')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _save,
        icon: const Icon(Icons.save_rounded),
        label: const Text('Save'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed: $e')),
        data: (m) {
          if (!_hydrated) {
            for (final k in _ctrls.keys) {
              _ctrls[k]!.text = m[k] ?? '';
            }
            _hydrated = true;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            children: _ctrls.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: TextField(
                  controller: e.value,
                  decoration: InputDecoration(
                    labelText: e.key[0].toUpperCase() + e.key.substring(1),
                    prefixIcon: Icon(_icons[e.key]),
                    suffixIcon: e.value.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.open_in_new_rounded),
                            onPressed: () {
                              final url = _resolve(e.key, e.value.text);
                              if (url != null) launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                            },
                          ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String? _resolve(String platform, String handle) {
    final h = handle.trim().replaceAll('@', '');
    if (h.isEmpty) return null;
    if (h.startsWith('http')) return h;
    switch (platform) {
      case 'instagram':
        return 'https://instagram.com/$h';
      case 'facebook':
        return 'https://facebook.com/$h';
      case 'twitter':
        return 'https://twitter.com/$h';
      case 'tiktok':
        return 'https://tiktok.com/@$h';
      case 'whatsapp':
        return 'https://wa.me/${h.replaceAll(RegExp(r'[^\d]'), '')}';
      case 'youtube':
        return 'https://youtube.com/@$h';
    }
    return null;
  }
}
