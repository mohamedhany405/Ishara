import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ishara_app/src/features/safety/data/emergency_contact_service.dart';

class _FakeEmergencyUrlLauncher implements EmergencyUrlLauncher {
  _FakeEmergencyUrlLauncher({this.allowedPrefixes = const <String>{}});

  final Set<String> allowedPrefixes;
  final List<Uri> canLaunchChecks = <Uri>[];
  final List<Uri> launchedUris = <Uri>[];

  @override
  Future<bool> canLaunch(Uri uri) async {
    canLaunchChecks.add(uri);
    return allowedPrefixes.any(uri.toString().startsWith);
  }

  @override
  Future<bool> launch(
    Uri uri, {
    LaunchMode mode = LaunchMode.platformDefault,
  }) async {
    launchedUris.add(uri);
    return true;
  }
}

void main() {
  group('EmergencyContactService deep links', () {
    tearDown(EmergencyContactService.resetLauncherForTesting);

    test(
      'opens WhatsApp native deep link with phone and prefilled message',
      () async {
        final launcher = _FakeEmergencyUrlLauncher(
          allowedPrefixes: const <String>{'whatsapp://send'},
        );
        EmergencyContactService.setLauncherForTesting(launcher);

        final contact = EmergencyContact(
          name: 'Emergency Contact',
          phone: '01012345678',
          preferredApp: SosMessagingApp.whatsapp,
        );

        final result = await EmergencyContactService.sendMessage(
          contact: contact,
          app: SosMessagingApp.whatsapp,
          message: 'Need urgent help now',
        );

        expect(result.success, isTrue);
        expect(result.usedFallback, isFalse);
        expect(launcher.launchedUris, hasLength(1));

        final launched = launcher.launchedUris.first.toString();
        expect(launched, startsWith('whatsapp://send?'));
        expect(launched, contains('phone=201012345678'));
        expect(launched, contains('text=Need%20urgent%20help%20now'));
      },
    );

    test(
      'opens Telegram native deep link with phone and prefilled message',
      () async {
        final launcher = _FakeEmergencyUrlLauncher(
          allowedPrefixes: const <String>{'tg://msg'},
        );
        EmergencyContactService.setLauncherForTesting(launcher);

        final contact = EmergencyContact(
          name: 'Emergency Contact',
          phone: '+201055001122',
          preferredApp: SosMessagingApp.telegram,
        );

        final result = await EmergencyContactService.sendMessage(
          contact: contact,
          app: SosMessagingApp.telegram,
          message: 'This is an emergency message',
        );

        expect(result.success, isTrue);
        expect(result.usedFallback, isFalse);
        expect(launcher.launchedUris, hasLength(1));

        final launched = launcher.launchedUris.first.toString();
        expect(launched, startsWith('tg://msg?'));
        expect(launched, contains('to=201055001122'));
        expect(launched, contains('text=This%20is%20an%20emergency%20message'));
      },
    );

    test('falls back to WhatsApp web when native app is unavailable', () async {
      final launcher = _FakeEmergencyUrlLauncher(
        allowedPrefixes: const <String>{'https://wa.me/'},
      );
      EmergencyContactService.setLauncherForTesting(launcher);

      final contact = EmergencyContact(
        name: 'Emergency Contact',
        phone: '01099998888',
        preferredApp: SosMessagingApp.whatsapp,
      );

      final result = await EmergencyContactService.sendMessage(
        contact: contact,
        app: SosMessagingApp.whatsapp,
        message: 'Please help me',
      );

      expect(result.success, isTrue);
      expect(result.usedFallback, isTrue);
      expect(result.message.toLowerCase(), contains('web'));
      expect(launcher.launchedUris, hasLength(1));
      expect(
        launcher.launchedUris.first.toString(),
        startsWith('https://wa.me/'),
      );
    });

    test(
      'falls back to Telegram download page when app and web contact links are unavailable',
      () async {
        final launcher = _FakeEmergencyUrlLauncher(
          allowedPrefixes: const <String>{'https://telegram.org/dl'},
        );
        EmergencyContactService.setLauncherForTesting(launcher);

        final contact = EmergencyContact(
          name: 'Emergency Contact',
          phone: '01077776666',
          preferredApp: SosMessagingApp.telegram,
        );

        final result = await EmergencyContactService.sendMessage(
          contact: contact,
          app: SosMessagingApp.telegram,
          message: 'Help needed',
        );

        expect(result.success, isTrue);
        expect(result.usedFallback, isTrue);
        expect(result.message.toLowerCase(), contains('download'));
        expect(launcher.launchedUris, hasLength(1));
        expect(
          launcher.launchedUris.first.toString(),
          equals('https://telegram.org/dl'),
        );
      },
    );

    test(
      'returns failure when no deep link or fallback can be launched',
      () async {
        final launcher = _FakeEmergencyUrlLauncher();
        EmergencyContactService.setLauncherForTesting(launcher);

        final contact = EmergencyContact(
          name: 'Emergency Contact',
          phone: '01011112222',
          preferredApp: SosMessagingApp.whatsapp,
        );

        final result = await EmergencyContactService.sendMessage(
          contact: contact,
          app: SosMessagingApp.whatsapp,
          message: 'Need help',
        );

        expect(result.success, isFalse);
        expect(launcher.launchedUris, isEmpty);
      },
    );
  });
}
