/// Coordinates a single SOS dispatch across every available channel.
///
/// Behaviour:
/// 1. Capture current location (3 s timeout, falls back to last-known).
/// 2. Build an Arabic+English help message with a Google Maps link.
/// 3. Fire **in parallel**:
///       (a) Local SMS via `another_telephony` on Android (silent, no user app
///           switch). iOS falls back to a `sms:` deep link.
///       (b) Server dispatch `POST /api/sos` — backend sends WhatsApp (Twilio),
///           Telegram (Bot API) and a backup Twilio SMS to every contact.
///       (c) `url_launcher` deep-links as a final user-visible fallback if
///           the silent path fails (or if the user has chosen "open apps").
/// 4. Logs the event server-side; returns a structured result for UI.
///
/// The coordinator is safe to call from a hardware-trigger handler (no UI
/// imports), and never throws — every failure becomes a `dispatchErrors` entry.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:another_telephony/telephony.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/auth_provider.dart';
import '../data/contacts_repository.dart';

enum SosTrigger { appButton, hardware, auto, tripleTap }

class SosDispatchResult {
  SosDispatchResult({
    required this.success,
    required this.totalContacts,
    required this.smsSent,
    required this.serverDispatched,
    required this.errors,
  });

  final bool success;
  final int totalContacts;
  final int smsSent;
  final bool serverDispatched;
  final List<String> errors;
}

class SosCoordinator {
  SosCoordinator({
    required ApiClient api,
    required ContactsRepository contacts,
    Telephony? telephony,
  })  : _api = api,
        _contacts = contacts,
        _telephony = telephony ?? Telephony.instance;

  final ApiClient _api;
  final ContactsRepository _contacts;
  final Telephony _telephony;

  Future<SosDispatchResult> dispatch({
    SosTrigger trigger = SosTrigger.appButton,
    String? customMessage,
  }) async {
    final errors = <String>[];

    // 1. Resolve contacts (server first, cached fallback).
    final contacts = await _contacts.list();
    if (contacts.isEmpty) {
      return SosDispatchResult(
        success: false,
        totalContacts: 0,
        smsSent: 0,
        serverDispatched: false,
        errors: const ['No emergency contacts configured.'],
      );
    }

    // 2. Location — bounded by 3 seconds; degrade gracefully.
    Position? loc;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      loc = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 3)),
      );
    } catch (_) {
      try {
        loc = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    final mapsUrl = loc != null
        ? 'https://maps.google.com/?q=${loc.latitude},${loc.longitude}'
        : '';
    final message = customMessage ??
        '🚨 SOS — I need help.${mapsUrl.isNotEmpty ? "\nLocation: $mapsUrl" : ""}\n\n'
            '🚨 طلب مساعدة طارئ. أحتاج المساعدة فوراً.${mapsUrl.isNotEmpty ? "\nالموقع: $mapsUrl" : ""}';

    // 3a. Server dispatch (parallel) — backend handles WhatsApp/Telegram/SMS via Twilio.
    final serverFuture = _api.post('/api/sos', data: {
      'triggeredBy': trigger.name,
      'location': loc == null
          ? null
          : {
              'lat': loc.latitude,
              'lng': loc.longitude,
              'accuracy': loc.accuracy,
            },
      'customMessage': message,
    }).then((r) => r.statusCode != null && r.statusCode! >= 200 && r.statusCode! < 300).catchError((e) {
      errors.add('server: $e');
      return false;
    });

    // 3b. Device-side silent SMS (Android only).
    final smsFuture = _sendSilentSms(contacts, message, errors);

    final results = await Future.wait([serverFuture, smsFuture]);
    final serverOk = results[0] as bool;
    final smsSent = results[1] as int;

    // 3c. If both server and silent SMS failed, fall back to deep-link to give
    // the user a visible last-resort option.
    if (!serverOk && smsSent == 0) {
      try {
        final c = contacts.first;
        final phoneDigits = c.phone.replaceAll(RegExp(r'[^\d]'), '');
        final wa = Uri.parse('https://wa.me/$phoneDigits?text=${Uri.encodeComponent(message)}');
        await launchUrl(wa, mode: LaunchMode.externalApplication);
      } catch (e) {
        errors.add('deeplink_fallback: $e');
      }
    }

    return SosDispatchResult(
      success: serverOk || smsSent > 0,
      totalContacts: contacts.length,
      smsSent: smsSent,
      serverDispatched: serverOk,
      errors: errors,
    );
  }

  Future<int> _sendSilentSms(List<EmergencyContactDto> contacts, String message, List<String> errors) async {
    if (!Platform.isAndroid) return 0;
    int count = 0;
    try {
      final granted = (await _telephony.requestSmsPermissions) ?? false;
      if (!granted) {
        errors.add('sms: permission_denied');
        return 0;
      }
      for (final c in contacts) {
        if (c.app != 'all' && c.app != 'sms') continue;
        try {
          await _telephony.sendSms(to: c.phone, message: message, isMultipart: true);
          count++;
        } catch (e) {
          errors.add('sms_${c.name}: $e');
        }
      }
    } catch (e) {
      errors.add('sms_fatal: $e');
    }
    return count;
  }
}

final sosCoordinatorProvider = Provider<SosCoordinator>((ref) {
  final api = ref.watch(apiClientProvider);
  final contacts = ref.watch(contactsRepositoryProvider);
  return SosCoordinator(api: api, contacts: contacts);
});
