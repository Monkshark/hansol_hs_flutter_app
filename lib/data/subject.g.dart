// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubjectImpl _$$SubjectImplFromJson(Map<String, dynamic> json) =>
    _$SubjectImpl(
      subjectName: json['subjectName'] as String,
      subjectClass: (json['subjectClass'] as num).toInt(),
      category: json['category'] as String?,
      isOriginal: json['isOriginal'] as bool? ?? false,
    );

Map<String, dynamic> _$$SubjectImplToJson(_$SubjectImpl instance) =>
    <String, dynamic>{
      'subjectName': instance.subjectName,
      'subjectClass': instance.subjectClass,
      'category': instance.category,
      'isOriginal': instance.isOriginal,
    };
