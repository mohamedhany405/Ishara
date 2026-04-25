/// Ishara in-app assistant — chat UI backed by `/api/chatbot/ask` (Gemini proxy).
///
/// Quick replies cover the most common how-to questions; deep-link tags like
/// `[open:safety]` in the assistant's reply route the user to the matching
/// screen with one tap.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/services/tts_service.dart';

class _Msg {
  _Msg({required this.role, required this.content});
  final String role; // user | assistant
  final String content;
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});
  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_Msg> _messages = [
    _Msg(role: 'assistant', content: 'مرحباً! Ask me how to use any feature of Ishara.'),
  ];
  bool _sending = false;

  static const _quickReplies = [
    'How do I add an emergency contact?',
    'Enable Auto-TTS',
    'How to translate signs',
    'Open the shop',
    'Run a quiz',
  ];

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _messages.add(_Msg(role: 'user', content: trimmed));
      _sending = true;
    });
    _ctrl.clear();
    _scrollDown();
    try {
      final api = ref.read(apiClientProvider);
      final r = await api.post('/api/chatbot/ask', data: {
        'messages': _messages.map((m) => {'role': m.role, 'content': m.content}).toList(),
      });
      final reply = (r.data['reply'] ?? '').toString();
      setState(() => _messages.add(_Msg(role: 'assistant', content: reply.isEmpty ? '...' : reply)));
      ref.read(ttsServiceProvider).speak(_stripTags(reply));
    } catch (e) {
      setState(() => _messages.add(_Msg(role: 'assistant', content: 'Sorry, I had trouble reaching the server.')));
    } finally {
      setState(() => _sending = false);
      _scrollDown();
    }
  }

  String _stripTags(String s) => s.replaceAll(RegExp(r'\[open:[^\]]+\]'), '').trim();

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  void _handleDeepLink(String reply) {
    final m = RegExp(r'\[open:([^\]]+)\]').firstMatch(reply);
    if (m == null) return;
    final target = m.group(1)!;
    final route = switch (target) {
      'translator' => '/translator',
      'vision' => '/vision',
      'safety' => '/safety',
      'learning' => '/learning',
      'shop' => '/shop',
      'profile/accessibility' => '/profile/accessibility',
      'profile/contacts' => '/profile/contacts',
      _ => null,
    };
    if (route != null) context.push(route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistant')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final isUser = m.role == 'user';
                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => isUser ? null : _handleDeepLink(m.content),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(isUser ? 14 : 4),
                            bottomRight: Radius.circular(isUser ? 4 : 14),
                          ),
                        ),
                        child: Text(
                          _stripTags(m.content),
                          style: TextStyle(color: isUser ? theme.colorScheme.onPrimary : null),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: _quickReplies.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(_quickReplies[i]),
                  onPressed: _sending ? null : () => _send(_quickReplies[i]),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    enabled: !_sending,
                    decoration: const InputDecoration(hintText: 'Ask anything…', border: OutlineInputBorder()),
                    onSubmitted: _send,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : () => _send(_ctrl.text),
                  icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.send_rounded),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
