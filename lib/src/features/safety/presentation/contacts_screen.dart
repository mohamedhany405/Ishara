/// Multi-contact emergency contacts manager.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/contacts_repository.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsListProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(contactsListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add contact'),
      ),
      body: contactsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load: $e')),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.contacts_rounded, size: 80, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Add at least one emergency contact so SOS can reach someone.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = list[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name.characters.first.toUpperCase())),
                  title: Text(c.name),
                  subtitle: Text('${c.phone}\n${c.relationship.isEmpty ? "—" : c.relationship} • ${c.app}'),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      if (v == 'edit') await _openEditor(context, ref, c);
                      if (v == 'delete') {
                        await ref.read(contactsRepositoryProvider).remove(c.id);
                        ref.invalidate(contactsListProvider);
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref, EmergencyContactDto? existing) async {
    final saved = await showModalBottomSheet<EmergencyContactDto>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ContactEditor(initial: existing),
    );
    if (saved == null) return;
    final repo = ref.read(contactsRepositoryProvider);
    if (existing == null) {
      await repo.add(saved);
    } else {
      await repo.update(saved);
    }
    ref.invalidate(contactsListProvider);
  }
}

class _ContactEditor extends StatefulWidget {
  const _ContactEditor({this.initial});
  final EmergencyContactDto? initial;
  @override
  State<_ContactEditor> createState() => _ContactEditorState();
}

class _ContactEditorState extends State<_ContactEditor> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _phone = TextEditingController(text: widget.initial?.phone ?? '');
  late final _rel = TextEditingController(text: widget.initial?.relationship ?? '');
  late final _tg = TextEditingController(text: widget.initial?.telegramChatId ?? '');
  late String _app = widget.initial?.app ?? 'all';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _rel.dispose();
    _tg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.initial == null ? 'Add contact' : 'Edit contact', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 8),
          TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone (with country code)'), keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          TextField(controller: _rel, decoration: const InputDecoration(labelText: 'Relationship')),
          const SizedBox(height: 8),
          TextField(controller: _tg, decoration: const InputDecoration(labelText: 'Telegram chat ID (optional)')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _app,
            decoration: const InputDecoration(labelText: 'Channels'),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All (WhatsApp + Telegram + SMS)')),
              DropdownMenuItem(value: 'whatsapp', child: Text('WhatsApp only')),
              DropdownMenuItem(value: 'telegram', child: Text('Telegram only')),
              DropdownMenuItem(value: 'sms', child: Text('SMS only')),
            ],
            onChanged: (v) => setState(() => _app = v ?? 'all'),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.save_rounded),
            onPressed: () {
              if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name and phone are required')),
                );
                return;
              }
              Navigator.of(context).pop(EmergencyContactDto(
                id: widget.initial?.id ?? '',
                name: _name.text.trim(),
                phone: _phone.text.trim(),
                relationship: _rel.text.trim(),
                app: _app,
                priority: widget.initial?.priority ?? 0,
                telegramChatId: _tg.text.trim(),
              ));
            },
            label: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
