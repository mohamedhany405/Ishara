import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/auth_provider.dart';
import '../../../core/api/data_service.dart';
import '../domain/learning_models.dart';

class LearningState {
  const LearningState({
    required this.lessons,
    required this.dictionary,
    required this.lessonSearchQuery,
    required this.dictionarySearchQuery,
    required this.selectedCategory,
    required this.crudVerified,
    required this.crudMessage,
    required this.isLoading,
    required this.error,
  });

  final List<LessonItem> lessons;
  final List<DictionaryEntry> dictionary;
  final String lessonSearchQuery;
  final String dictionarySearchQuery;
  final String? selectedCategory;
  final bool crudVerified;
  final String? crudMessage;
  final bool isLoading;
  final String? error;

  LearningState copyWith({
    List<LessonItem>? lessons,
    List<DictionaryEntry>? dictionary,
    String? lessonSearchQuery,
    String? dictionarySearchQuery,
    String? selectedCategory,
    bool? crudVerified,
    String? crudMessage,
    bool? isLoading,
    String? error,
  }) {
    return LearningState(
      lessons: lessons ?? this.lessons,
      dictionary: dictionary ?? this.dictionary,
      lessonSearchQuery: lessonSearchQuery ?? this.lessonSearchQuery,
      dictionarySearchQuery:
          dictionarySearchQuery ?? this.dictionarySearchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      crudVerified: crudVerified ?? this.crudVerified,
      crudMessage: crudMessage ?? this.crudMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  static LearningState get initial => const LearningState(
    lessons: [],
    dictionary: [],
    lessonSearchQuery: '',
    dictionarySearchQuery: '',
    selectedCategory: null,
    crudVerified: false,
    crudMessage: null,
    isLoading: false,
    error: null,
  );
}

class LearningController extends StateNotifier<LearningState> {
  LearningController(this._dataService) : super(LearningState.initial) {
    load();
  }

  final DataService _dataService;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final lessonsResult = await _dataService.getLearningLessons();
      final dictionaryResult = await _dataService.getLearningDictionary();

      final lessons =
          lessonsResult.success && (lessonsResult.data?.isNotEmpty ?? false)
              ? lessonsResult.data!.map(_mapLesson).toList()
              : _defaultLessons();

      final dictionary =
          dictionaryResult.success &&
                  (dictionaryResult.data?.isNotEmpty ?? false)
              ? dictionaryResult.data!.map(_mapDictionary).toList()
              : _defaultDictionary();

      String? error;
      if (!lessonsResult.success || !dictionaryResult.success) {
        error = 'Cloud sync unavailable. Showing offline learning content.';
      }

      final crud = await _dataService.verifyDatabaseCrud();

      state = state.copyWith(
        lessons: lessons,
        dictionary: dictionary,
        crudVerified: crud.success,
        crudMessage: crud.message,
        isLoading: false,
        error: error,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  LessonItem _mapLesson(Map<String, dynamic> data) {
    return LessonItem(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? 'Untitled lesson',
      description: data['description']?.toString() ?? '',
      category: data['category']?.toString() ?? 'beginner',
      videoUrl: data['videoUrl']?.toString(),
      thumbnailUrl: data['thumbnailUrl']?.toString(),
      durationSeconds: data['durationSeconds'] as int?,
    );
  }

  DictionaryEntry _mapDictionary(Map<String, dynamic> data) {
    return DictionaryEntry(
      id: data['id']?.toString() ?? '',
      wordAr: data['wordAr']?.toString() ?? '',
      wordEn: data['wordEn']?.toString() ?? '',
      description: data['description']?.toString(),
      videoUrl: data['videoUrl']?.toString(),
      category: data['category']?.toString(),
    );
  }

  List<LessonItem> _defaultLessons() {
    return [
      const LessonItem(
        id: 'lesson_hello',
        title: 'Greetings - Hello',
        description: 'Learn the sign for Hello (مرحبا).',
        category: 'beginner',
        videoUrl: 'https://www.youtube.com/watch?v=I5gUHigXsR8',
      ),
      const LessonItem(
        id: 'lesson_thanks',
        title: 'Daily - Thank You',
        description: 'Learn the sign for Thank You (شكرا).',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=Hw6EiHwH_iI',
      ),
      const LessonItem(
        id: 'lesson_help',
        title: 'Emergency - Help',
        description: 'Learn the emergency sign for Help (مساعدة).',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=tFA4BnbEdMw',
      ),
      const LessonItem(
        id: 'lesson_doctor',
        title: 'Emergency - Doctor',
        description: 'Learn the sign for Doctor (دكتور).',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=pACOwc9uLnY',
      ),
      const LessonItem(
        id: 'lesson_police',
        title: 'Emergency - Police',
        description: 'Learn the sign for Police (شرطة).',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=dtrgursVHyY',
      ),
      const LessonItem(
        id: 'lesson_water',
        title: 'Daily - Water',
        description: 'Learn the sign for Water (ماء).',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=pG9fdWR_Qcs',
      ),
    ];
  }

  List<DictionaryEntry> _defaultDictionary() {
    return const [
      DictionaryEntry(
        id: 'dict_hello',
        wordAr: 'مرحبا',
        wordEn: 'Hello',
        category: 'greetings',
        videoUrl: 'https://www.youtube.com/watch?v=I5gUHigXsR8',
      ),
      DictionaryEntry(
        id: 'dict_thanks',
        wordAr: 'شكرا',
        wordEn: 'Thank You',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=Hw6EiHwH_iI',
      ),
      DictionaryEntry(
        id: 'dict_help',
        wordAr: 'مساعدة',
        wordEn: 'Help',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=tFA4BnbEdMw',
      ),
      DictionaryEntry(
        id: 'dict_doctor',
        wordAr: 'دكتور',
        wordEn: 'Doctor',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=pACOwc9uLnY',
      ),
      DictionaryEntry(
        id: 'dict_police',
        wordAr: 'شرطة',
        wordEn: 'Police',
        category: 'emergency',
        videoUrl: 'https://www.youtube.com/watch?v=dtrgursVHyY',
      ),
      DictionaryEntry(
        id: 'dict_water',
        wordAr: 'ماء',
        wordEn: 'Water',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=pG9fdWR_Qcs',
      ),
      DictionaryEntry(
        id: 'dict_where',
        wordAr: 'أين',
        wordEn: 'Where',
        category: 'questions',
        videoUrl: 'https://www.youtube.com/watch?v=-OixvXUf_lc',
      ),
      DictionaryEntry(
        id: 'dict_yes',
        wordAr: 'نعم',
        wordEn: 'Yes',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=JDofZ1ESnIk',
      ),
      DictionaryEntry(
        id: 'dict_no',
        wordAr: 'لا',
        wordEn: 'No',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=r3JksZ2xSM4',
      ),
      DictionaryEntry(
        id: 'dict_i',
        wordAr: 'أنا',
        wordEn: 'I / Me',
        category: 'daily',
        videoUrl: 'https://www.youtube.com/watch?v=sxU3WlDaGbY',
      ),
      DictionaryEntry(
        id: 'dict_father',
        wordAr: 'أب',
        wordEn: 'Father',
        category: 'family',
        videoUrl: 'https://www.youtube.com/watch?v=c-q-U_WsiM8',
      ),
      DictionaryEntry(
        id: 'dict_mother',
        wordAr: 'أم',
        wordEn: 'Mother',
        category: 'family',
        videoUrl: 'https://www.youtube.com/watch?v=lmjA9WW5mYE',
      ),
    ];
  }

  void setLessonSearchQuery(String q) {
    state = state.copyWith(lessonSearchQuery: q);
  }

  void setDictionarySearchQuery(String q) {
    state = state.copyWith(dictionarySearchQuery: q);
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  Future<void> refresh() async {
    await load();
  }
}

final learningControllerProvider =
    StateNotifierProvider<LearningController, LearningState>((ref) {
      final dataService = ref.watch(dataServiceProvider);
      return LearningController(dataService);
    });

final filteredLessonsProvider = Provider<List<LessonItem>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.lessons;
  if (state.selectedCategory != null) {
    list = list.where((l) => l.category == state.selectedCategory).toList();
  }
  if (state.lessonSearchQuery.isNotEmpty) {
    final q = state.lessonSearchQuery.toLowerCase();
    list =
        list
            .where(
              (l) =>
                  l.title.toLowerCase().contains(q) ||
                  l.description.toLowerCase().contains(q),
            )
            .toList();
  }
  return list;
});

final filteredDictionaryProvider = Provider<List<DictionaryEntry>>((ref) {
  final state = ref.watch(learningControllerProvider);
  var list = state.dictionary;
  if (state.dictionarySearchQuery.isNotEmpty) {
    final q = state.dictionarySearchQuery.toLowerCase();
    list =
        list
            .where(
              (e) => e.wordAr.contains(q) || e.wordEn.toLowerCase().contains(q),
            )
            .toList();
  }
  if (state.selectedCategory != null) {
    list = list.where((e) => e.category == state.selectedCategory).toList();
  }
  return list;
});
