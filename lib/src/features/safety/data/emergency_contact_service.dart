import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum SosMessagingApp { whatsapp, telegram }

class EmergencyLaunchResult {
  const EmergencyLaunchResult({
    required this.success,
    required this.message,
    this.usedFallback = false,
  });

  final bool success;
  final String message;
  final bool usedFallback;
}

abstract class EmergencyUrlLauncher {
  Future<bool> canLaunch(Uri uri);

  Future<bool> launch(Uri uri, {LaunchMode mode});
}

class _SystemEmergencyUrlLauncher implements EmergencyUrlLauncher {
  const _SystemEmergencyUrlLauncher();

  @override
  Future<bool> canLaunch(Uri uri) {
    return canLaunchUrl(uri);
  }

  @override
  Future<bool> launch(Uri uri, {LaunchMode mode = LaunchMode.platformDefault}) {
    return launchUrl(uri, mode: mode);
  }
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.preferredApp,
  });

  final String name;
  final String phone;
  final SosMessagingApp preferredApp;

  bool get isValid => name.isNotEmpty && phone.isNotEmpty;

  static const String _keyName = 'sos_contact_name';
  static const String _keyPhone = 'sos_contact_phone';
  static const String _keyApp = 'sos_contact_app';

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyApp, preferredApp.name);
  }

  static Future<EmergencyContact?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString(_keyName) ?? '';
    final phone = prefs.getString(_keyPhone) ?? '';
    final appStr = prefs.getString(_keyApp) ?? '';
    if (name.isEmpty || phone.isEmpty) return null;
    final app = SosMessagingApp.values.firstWhere(
      (e) => e.name == appStr,
      orElse: () => SosMessagingApp.whatsapp,
    );
    return EmergencyContact(name: name, phone: phone, preferredApp: app);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyApp);
  }
}

class EmergencyContactService {
  static EmergencyUrlLauncher _launcher = const _SystemEmergencyUrlLauncher();

  @visibleForTesting
  static void setLauncherForTesting(EmergencyUrlLauncher launcher) {
    _launcher = launcher;
  }

  @visibleForTesting
  static void resetLauncherForTesting() {
    _launcher = const _SystemEmergencyUrlLauncher();
  }

  static Future<EmergencyLaunchResult> sendSosMessage({
    required EmergencyContact contact,
    required Position position,
  }) async {
    final mapsLink =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    final message =
        'SOS emergency: I need urgent help. My current location is: $mapsLink';
    return sendMessage(
      contact: contact,
      app: contact.preferredApp,
      message: message,
    );
  }

  static Future<EmergencyLaunchResult> sendMessage({
    required EmergencyContact contact,
    required SosMessagingApp app,
    required String message,
  }) async {
    final normalizedPhone = _normalizePhone(contact.phone);
    if (normalizedPhone == null) {
      return const EmergencyLaunchResult(
        success: false,
        message: 'Invalid emergency contact phone number.',
      );
    }

    final rawPhone = normalizedPhone.replaceFirst('+', '');
    final encodedMessage = Uri.encodeComponent(message);

    if (app == SosMessagingApp.whatsapp) {
      return _sendWhatsApp(rawPhone: rawPhone, encodedMessage: encodedMessage);
    }

    return _sendTelegram(rawPhone: rawPhone, encodedMessage: encodedMessage);
  }

  static Future<EmergencyLaunchResult> _sendWhatsApp({
    required String rawPhone,
    required String encodedMessage,
  }) async {
    final nativeUri = Uri.parse(
      'whatsapp://send?phone=$rawPhone&text=$encodedMessage',
    );
    if (await _launchIfPossible(nativeUri)) {
      return const EmergencyLaunchResult(
        success: true,
        message: 'Opened WhatsApp with the pre-filled emergency message.',
      );
    }

    final webUri = Uri.parse('https://wa.me/$rawPhone?text=$encodedMessage');
    if (await _launchIfPossible(webUri)) {
      return const EmergencyLaunchResult(
        success: true,
        usedFallback: true,
        message:
            'WhatsApp is not installed. Opened WhatsApp web with the emergency message.',
      );
    }

    final storeUri = Uri.parse('https://www.whatsapp.com/download');
    if (await _launchIfPossible(storeUri)) {
      return const EmergencyLaunchResult(
        success: true,
        usedFallback: true,
        message:
            'WhatsApp is not installed. Opened the WhatsApp download page.',
      );
    }

    return const EmergencyLaunchResult(
      success: false,
      message: 'Could not open WhatsApp. Please install it and try again.',
    );
  }

  static Future<EmergencyLaunchResult> _sendTelegram({
    required String rawPhone,
    required String encodedMessage,
  }) async {
    final nativeUri = Uri.parse('tg://msg?to=$rawPhone&text=$encodedMessage');
    if (await _launchIfPossible(nativeUri)) {
      return const EmergencyLaunchResult(
        success: true,
        message: 'Opened Telegram with the pre-filled emergency message.',
      );
    }

    final resolveUri = Uri.parse(
      'tg://resolve?phone=$rawPhone&text=$encodedMessage',
    );
    if (await _launchIfPossible(resolveUri)) {
      return const EmergencyLaunchResult(
        success: true,
        message: 'Opened Telegram with the pre-filled emergency message.',
      );
    }

    final contactWebUri = Uri.parse(
      'https://t.me/+$rawPhone?text=$encodedMessage',
    );
    if (await _launchIfPossible(contactWebUri)) {
      return const EmergencyLaunchResult(
        success: true,
        usedFallback: true,
        message:
            'Telegram is not installed. Opened Telegram web with the emergency message.',
      );
    }

    final shareWebUri = Uri.parse(
      'https://t.me/share/url?text=$encodedMessage',
    );
    if (await _launchIfPossible(shareWebUri)) {
      return const EmergencyLaunchResult(
        success: true,
        usedFallback: true,
        message:
            'Telegram is not installed. Opened Telegram web with a pre-filled emergency message.',
      );
    }

    final storeUri = Uri.parse('https://telegram.org/dl');
    if (await _launchIfPossible(storeUri)) {
      return const EmergencyLaunchResult(
        success: true,
        usedFallback: true,
        message:
            'Telegram is not installed. Opened the Telegram download page.',
      );
    }

    return const EmergencyLaunchResult(
      success: false,
      message: 'Could not open Telegram. Please install it and try again.',
    );
  }

  static Future<bool> _launchIfPossible(Uri uri) async {
    if (await _launcher.canLaunch(uri)) {
      return _launcher.launch(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static String? _normalizePhone(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    var cleaned = trimmed.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('+')) {
      final digitsOnly = cleaned.substring(1).replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.isEmpty) return null;
      return '+$digitsOnly';
    }

    cleaned = cleaned.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;

    if (cleaned.startsWith('00') && cleaned.length > 2) {
      return '+${cleaned.substring(2)}';
    }

    if (cleaned.startsWith('0')) {
      return '+20${cleaned.substring(1)}';
    }

    if (cleaned.startsWith('20')) {
      return '+$cleaned';
    }

    return '+$cleaned';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────
final emergencyContactProvider =
    StateNotifierProvider<EmergencyContactNotifier, EmergencyContact?>(
      (ref) => EmergencyContactNotifier()..load(),
    );

class EmergencyContactNotifier extends StateNotifier<EmergencyContact?> {
  EmergencyContactNotifier() : super(null);

  Future<void> load() async {
    state = await EmergencyContact.load();
  }

  Future<void> save(EmergencyContact contact) async {
    await contact.save();
    state = contact;
  }

  Future<void> clear() async {
    await EmergencyContact.clear();
    state = null;
  }
}
