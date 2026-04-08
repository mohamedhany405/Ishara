import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

enum SosMessagingApp { whatsapp, telegram }

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
  /// Sends the SOS message via WhatsApp or Telegram deep-link.
  /// Returns true if the link was launched successfully.
  static Future<bool> sendSosMessage({
    required EmergencyContact contact,
    required Position position,
  }) async {
    final mapsLink =
        'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    final message = Uri.encodeComponent(
      '🆘 SOS! أحتاج مساعدة عاجلة. موقعي الحالي:\n$mapsLink',
    );

    // Normalise phone: remove spaces and leading zeros, add country code if missing
    var phone = contact.phone.replaceAll(RegExp(r'\s+'), '');
    if (phone.startsWith('0')) phone = '+20${phone.substring(1)}';
    if (!phone.startsWith('+')) phone = '+$phone';
    final rawPhone = phone.replaceAll('+', '');

    Uri uri;
    if (contact.preferredApp == SosMessagingApp.whatsapp) {
      uri = Uri.parse('whatsapp://send?phone=$rawPhone&text=$message');
    } else {
      uri = Uri.parse('tg://msg?to=$rawPhone&text=$message');
    }

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Fallback: open SMS
    final smsUri = Uri.parse(
        'sms:$phone?body=${Uri.encodeComponent('🆘 SOS! أحتاج مساعدة. موقعي: $mapsLink')}');
    if (await canLaunchUrl(smsUri)) {
      return launchUrl(smsUri);
    }
    return false;
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
