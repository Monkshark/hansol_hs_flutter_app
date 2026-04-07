// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealImpl _$$MealImplFromJson(Map<String, dynamic> json) => _$MealImpl(
      meal: json['meal'] as String?,
      date: DateTime.parse(json['date'] as String),
      mealType: (json['mealType'] as num).toInt(),
      kcal: json['kcal'] as String,
      ntrInfo: json['ntrInfo'] as String? ?? '',
    );

Map<String, dynamic> _$$MealImplToJson(_$MealImpl instance) =>
    <String, dynamic>{
      'meal': instance.meal,
      'date': instance.date.toIso8601String(),
      'mealType': instance.mealType,
      'kcal': instance.kcal,
      'ntrInfo': instance.ntrInfo,
    };
