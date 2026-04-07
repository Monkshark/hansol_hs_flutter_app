import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject.freezed.dart';
part 'subject.g.dart';

/// 과목 데이터 모델 (freezed)
///
/// - 과목명, 반 번호, 카테고리(선택), 원본 여부 포함
/// - JSON 직렬화/역직렬화는 json_serializable이 자동 생성
/// - 동등성 비교는 subjectName/subjectClass 기준 (커스텀 ==)
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
