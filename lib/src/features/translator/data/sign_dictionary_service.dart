/// Looks up a clip path for an Arabic word, falling back to per-letter
/// finger-spelling when the word isn't in the dictionary.
///
/// Loaded once from `assets/sign_dictionary.json` and cached.
library;

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignDictionary {
  SignDictionary._(this.words, this.letters);
  final Map<String, String> words;
  final Map<String, String> letters;

  /// Strips Arabic diacritics & tatweel, normalises hamza variants.
  static String normalize(String s) {
    final cleaned = s
        .replaceAll(RegExp('[ً-ٰٟـ]'), '') // diacritics+tatweel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');
    return cleaned.trim();
  }

  String? lookupWord(String word) {
    final w = word.trim();
    if (w.isEmpty) return null;
    return words[w] ?? words[normalize(w)];
  }

  /// Returns one clip per character (skipping unknown chars).
  List<String> spell(String word) {
    final out = <String>[];
    for (final ch in word.split('')) {
      final clip = letters[ch] ?? letters[normalize(ch)];
      if (clip != null) out.add(clip);
    }
    return out;
  }

  /// Build an ordered playlist for an Arabic phrase.
  /// Each entry is { 'kind': 'word'|'spell', 'token': str, 'clip': str }.
  List<SignToken> tokenize(String text) {
    final cleaned = text.replaceAll(RegExp(r'[^؀-ۿa-zA-Z\s]'), ' ');
    final tokens = cleaned.split(RegExp(r'\s+')).where((t) => t.isNotEmpty);
    final out = <SignToken>[];
    for (final tok in tokens) {
      final wordClip = lookupWord(tok);
      if (wordClip != null) {
        out.add(SignToken(kind: SignTokenKind.word, token: tok, clip: wordClip));
      } else {
        for (final ch in tok.split('')) {
          final letterClip = letters[ch] ?? letters[normalize(ch)];
          if (letterClip != null) {
            out.add(SignToken(kind: SignTokenKind.letter, token: ch, clip: letterClip));
          } else {
            out.add(SignToken(kind: SignTokenKind.unknown, token: ch, clip: ''));
          }
        }
      }
    }
    return out;
  }
}

enum SignTokenKind { word, letter, unknown }

class SignToken {
  const SignToken({required this.kind, required this.token, required this.clip});
  final SignTokenKind kind;
  final String token;
  final String clip;
}

final signDictionaryProvider = FutureProvider<SignDictionary>((ref) async {
  final raw = await rootBundle.loadString('assets/sign_dictionary.json');
  final data = jsonDecode(raw) as Map<String, dynamic>;
  final words = (data['words'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
  final letters = (data['letters'] as Map<String, dynamic>).map((k, v) => MapEntry(k, v.toString()));
  return SignDictionary._(words, letters);
});
