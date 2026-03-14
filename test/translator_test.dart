import 'package:flutter_test/flutter_test.dart';

import 'package:ishara_app/src/features/translator/domain/esl_translation_models.dart';
import 'package:ishara_app/src/features/translator/data/esl_translator_service.dart';

void main() {
  group('EslTranslationModels', () {
    test('QuickPhrase equality', () {
      const a = QuickPhrase(
        id: '1',
        label: 'Help',
        text: 'مساعدة',
        category: 'emergency',
      );
      const b = QuickPhrase(
        id: '1',
        label: 'Help',
        text: 'مساعدة',
        category: 'emergency',
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('EslTranslationDirection enum', () {
      expect(EslTranslationDirection.values.length, 2);
    });
  });

  group('StubEslTranslator', () {
    test('translate returns result with correct direction', () async {
      final translator = StubEslTranslator();
      final result = await translator.translate(
        direction: EslTranslationDirection.eslToArabic,
        textInput: 'hello',
      );
      expect(result.direction, EslTranslationDirection.eslToArabic);
      expect(result.inputText, 'hello');
      expect(result.outputText, isNotEmpty);
      expect(result.confidence, inInclusiveRange(0.0, 1.0));
    });

    test('translate arabicToEsl returns non-empty output', () async {
      final translator = StubEslTranslator();
      final result = await translator.translate(
        direction: EslTranslationDirection.arabicToEsl,
        textInput: 'مرحبا',
      );
      expect(result.direction, EslTranslationDirection.arabicToEsl);
      expect(result.outputText, isNotEmpty);
    });
  });
}
