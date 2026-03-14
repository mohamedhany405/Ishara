import 'package:equatable/equatable.dart';

class LessonItem extends Equatable {
  const LessonItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.videoUrl,
    this.thumbnailUrl,
    this.durationSeconds,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String? videoUrl;
  final String? thumbnailUrl;
  final int? durationSeconds;

  @override
  List<Object?> get props => [id, title, description, category];
}

class DictionaryEntry extends Equatable {
  const DictionaryEntry({
    required this.id,
    required this.wordAr,
    required this.wordEn,
    this.description,
    this.videoUrl,
    this.category,
  });

  final String id;
  final String wordAr;
  final String wordEn;
  final String? description;
  final String? videoUrl;
  final String? category;

  @override
  List<Object?> get props => [id, wordAr, wordEn];
}
