import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning_models.dart';

class LearningState {
  const LearningState({
    required this.lessons,
    required this.dictionary,
    required this.lessonSearchQuery,
    required this.dictSearchQuery,
    required this.selectedCategory,
    required this.isLoading,
    required this.error,
  });

  final List<LessonItem> lessons;
  final List<DictionaryEntry> dictionary;
  final String lessonSearchQuery;
  final String dictSearchQuery;
  final String? selectedCategory;
  final bool isLoading;
  final String? error;

  LearningState copyWith({
    List<LessonItem>? lessons,
    List<DictionaryEntry>? dictionary,
    String? lessonSearchQuery,
    String? dictSearchQuery,
    // Use Object? to allow clearing (setting to null)
    Object? selectedCategory = const _Sentinel(),
    bool? isLoading,
    String? error,
  }) {
    return LearningState(
      lessons: lessons ?? this.lessons,
      dictionary: dictionary ?? this.dictionary,
      lessonSearchQuery: lessonSearchQuery ?? this.lessonSearchQuery,
      dictSearchQuery: dictSearchQuery ?? this.dictSearchQuery,
      selectedCategory: selectedCategory is _Sentinel
          ? this.selectedCategory
          : selectedCategory as String?,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static LearningState get initial => const LearningState(
        lessons: [],
        dictionary: [],
        lessonSearchQuery: '',
        dictSearchQuery: '',
        selectedCategory: null,
        isLoading: false,
        error: null,
      );
}

/// Sentinel class to distinguish "not provided" from "explicitly null"
class _Sentinel {
  const _Sentinel();
}

class LearningController extends StateNotifier<LearningState> {
  LearningController([SharedPreferences? prefs])
      : _prefs = prefs,
        super(LearningState.initial) {
    load();
  }

  final SharedPreferences? _prefs;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final lessons = _defaultLessons();
      final dictionary = _defaultDictionary();
      state = state.copyWith(
        lessons: lessons,
        dictionary: dictionary,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  List<LessonItem> _defaultLessons() {
    return const [
      LessonItem(
        id: '1',
        title: 'Greetings',
        description: 'Learn hello, goodbye, and basic greetings in ESL.',
        category: 'beginner',
        videoUrl: 'dQw4w9WgXcQ', // placeholder YouTube ID
      ),
      LessonItem(
        id: '2',
        title: 'Numbers 1–10',
        description: 'Count from one to ten in sign language.',
        category: 'beginner',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '3',
        title: 'Emergency phrases',
        description: 'Help, doctor, police, and urgent needs.',
        category: 'emergency',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '4',
        title: 'Daily phrases',
        description: 'Thank you, please, sorry, and common expressions.',
        category: 'daily',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '5',
        title: 'Family members',
        description: 'Father, mother, brother, sister, and more.',
        category: 'beginner',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '6',
        title: 'Directions',
        description: 'Left, right, up, down, and navigation signs.',
        category: 'daily',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '7',
        title: 'Feelings & Emotions',
        description: 'Express happy, sad, angry, and more.',
        category: 'beginner',
        videoUrl: 'dQw4w9WgXcQ',
      ),
      LessonItem(
        id: '8',
        title: 'Medical emergencies',
        description: 'Hospital, ambulance, medicine, pain.',
        category: 'emergency',
        videoUrl: 'dQw4w9WgXcQ',
      ),
    ];
  }

  List<DictionaryEntry> _defaultDictionary() {
    return const [
      DictionaryEntry(
        id: '1',
        wordAr: 'مرحبا',
        wordEn: 'Hello',
        description: 'A common greeting used when meeting someone.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'greetings',
      ),
      DictionaryEntry(
        id: '2',
        wordAr: 'شكرا',
        wordEn: 'Thank you',
        description: 'Expression of gratitude. One of the most important signs to learn.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
      DictionaryEntry(
        id: '3',
        wordAr: 'مساعدة',
        wordEn: 'Help',
        description: 'Used to call for assistance in urgent situations.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'emergency',
      ),
      DictionaryEntry(
        id: '4',
        wordAr: 'طبيب',
        wordEn: 'Doctor',
        description: 'Medical professional who treats patients.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'emergency',
      ),
      DictionaryEntry(
        id: '5',
        wordAr: 'شرطة',
        wordEn: 'Police',
        description: 'Law enforcement officer. Critical emergency sign.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'emergency',
      ),
      DictionaryEntry(
        id: '6',
        wordAr: 'ماء',
        wordEn: 'Water',
        description: 'Essential daily word. Common sign in daily communication.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
      DictionaryEntry(
        id: '7',
        wordAr: 'أين',
        wordEn: 'Where',
        description: 'Question word used to ask about locations.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'questions',
      ),
      DictionaryEntry(
        id: '8',
        wordAr: 'نعم',
        wordEn: 'Yes',
        description: 'Affirmative response. One of the first signs to learn.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
      DictionaryEntry(
        id: '9',
        wordAr: 'لا',
        wordEn: 'No',
        description: 'Negative response. Essential communication sign.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
      DictionaryEntry(
        id: '10',
        wordAr: 'أنا',
        wordEn: 'I / Me',
        description: 'Self-referencing pronoun. Fundamental in sentence construction.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'greetings',
      ),
      DictionaryEntry(
        id: '11',
        wordAr: 'أب',
        wordEn: 'Father',
        description: 'Family member sign. Part of the family category.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
      DictionaryEntry(
        id: '12',
        wordAr: 'أم',
        wordEn: 'Mother',
        description: 'Family member sign. Part of the family category.',
        videoUrl: 'dQw4w9WgXcQ',
        category: 'daily',
      ),
    ];
  }

  void setLessonSearchQuery(String q) {
    state = state.copyWith(lessonSearchQuery: q);
  }

  void setDictSearchQuery(String q) {
    state = state.copyWith(dictSearchQuery: q);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> refresh() async {
    await load();
  }
}

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final learningControllerProvider =
    StateNotifierProvider<LearningController, LearningState>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);
  return LearningController(prefsAsync.valueOrNull);
});

// ── Filtered providers (separate searches) ──────────────────────────────────
final filteredLessonsProvider = Provider<List<LessonItem>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.lessons;
  if (state.selectedCategory != null) {
    list = list.where((l) => l.category == state.selectedCategory).toList();
  }
  if (state.lessonSearchQuery.isNotEmpty) {
    final q = state.lessonSearchQuery.toLowerCase();
    list = list.where((l) =>
        l.title.toLowerCase().contains(q) ||
        l.description.toLowerCase().contains(q)).toList();
  }
  return list;
});

final filteredDictionaryProvider = Provider<List<DictionaryEntry>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.dictionary;
  // Dictionary uses its own search query – categories do NOT filter dictionary
  if (state.dictSearchQuery.isNotEmpty) {
    final q = state.dictSearchQuery.toLowerCase();
    list = list.where((e) =>
        e.wordAr.contains(q) ||
        e.wordEn.toLowerCase().contains(q)).toList();
  }
  return list;
});
