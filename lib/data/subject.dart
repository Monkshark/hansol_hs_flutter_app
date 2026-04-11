import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';
part 'subject.g.dart';

@freezed
class Subject with _$Subject {
  const Subject._();

  const factory Subject({
    required String subjectName,
    required int subjectClass,
    String? category,
    @Default(false) bool isOriginal,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) => _$SubjectFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subject &&
          runtimeType == other.runtimeType &&
          subjectName == other.subjectName &&
          subjectClass == other.subjectClass;

  @override
  int get hashCode => subjectName.hashCode ^ subjectClass.hashCode;
}
