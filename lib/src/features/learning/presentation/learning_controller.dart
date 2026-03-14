import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/learning_models.dart';

class LearningState {
  const LearningState({
    required this.lessons,
    required this.dictionary,
    required this.searchQuery,
    required this.selectedCategory,
    required this.isLoading,
    required this.error,
  });

  final List<LessonItem> lessons;
  final List<DictionaryEntry> dictionary;
  final String searchQuery;
  final String? selectedCategory;
  final bool isLoading;
  final String? error;

  LearningState copyWith({
    List<LessonItem>? lessons,
    List<DictionaryEntry>? dictionary,
    String? searchQuery,
    String? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return LearningState(
      lessons: lessons ?? this.lessons,
      dictionary: dictionary ?? this.dictionary,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static LearningState get initial => const LearningState(
        lessons: [],
        dictionary: [],
        searchQuery: '',
        selectedCategory: null,
        isLoading: false,
        error: null,
      );
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
    return [
      const LessonItem(
        id: '1',
        title: 'Greetings',
        description: 'Learn hello, goodbye, and basic greetings in ESL.',
        category: 'beginner',
        videoUrl: null,
      ),
      const LessonItem(
        id: '2',
        title: 'Numbers 1–10',
        description: 'Count from one to ten in sign language.',
        category: 'beginner',
        videoUrl: null,
      ),
      const LessonItem(
        id: '3',
        title: 'Emergency phrases',
        description: 'Help, doctor, police, and urgent needs.',
        category: 'emergency',
        videoUrl: null,
      ),
      const LessonItem(
        id: '4',
        title: 'Daily phrases',
        description: 'Thank you, please, sorry, and common expressions.',
        category: 'daily',
        videoUrl: null,
      ),
    ];
  }

  List<DictionaryEntry> _defaultDictionary() {
    return const [
      DictionaryEntry(id: '1', wordAr: 'مرحبا', wordEn: 'Hello', category: 'greetings'),
      DictionaryEntry(id: '2', wordAr: 'شكرا', wordEn: 'Thank you', category: 'daily'),
      DictionaryEntry(id: '3', wordAr: 'مساعدة', wordEn: 'Help', category: 'emergency'),
      DictionaryEntry(id: '4', wordAr: 'طبيب', wordEn: 'Doctor', category: 'emergency'),
      DictionaryEntry(id: '5', wordAr: 'شرطة', wordEn: 'Police', category: 'emergency'),
      DictionaryEntry(id: '6', wordAr: 'ماء', wordEn: 'Water', category: 'daily'),
      DictionaryEntry(id: '7', wordAr: 'أين', wordEn: 'Where', category: 'questions'),
    ];
  }

  void setSearchQuery(String q) {
    state = state.copyWith(searchQuery: q);
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

final filteredLessonsProvider = Provider<List<LessonItem>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.lessons;
  if (state.selectedCategory != null) {
    list = list.where((l) => l.category == state.selectedCategory).toList();
  }
  if (state.searchQuery.isNotEmpty) {
    final q = state.searchQuery.toLowerCase();
    list = list.where((l) =>
        l.title.toLowerCase().contains(q) ||
        l.description.toLowerCase().contains(q)).toList();
  }
  return list;
});

final filteredDictionaryProvider = Provider<List<DictionaryEntry>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.dictionary;
  if (state.searchQuery.isNotEmpty) {
    final q = state.searchQuery.toLowerCase();
    list = list.where((e) =>
        e.wordAr.contains(q) ||
        e.wordEn.toLowerCase().contains(q)).toList();
  }
  if (state.selectedCategory != null) {
    list = list.where((e) => e.category == state.selectedCategory).toList();
  }
  return list;
});
