// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subject.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Subject _$SubjectFromJson(Map<String, dynamic> json) {
  return _Subject.fromJson(json);
}

/// @nodoc
mixin _$Subject {
  String get subjectName => throw _privateConstructorUsedError;
  int get subjectClass => throw _privateConstructorUsedError;
  String? get category => throw _privateConstructorUsedError;
  bool get isOriginal => throw _privateConstructorUsedError;

  /// Serializes this Subject to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubjectCopyWith<Subject> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubjectCopyWith<$Res> {
  factory $SubjectCopyWith(Subject value, $Res Function(Subject) then) =
      _$SubjectCopyWithImpl<$Res, Subject>;
  @useResult
  $Res call(
      {String subjectName,
      int subjectClass,
      String? category,
      bool isOriginal});
}

/// @nodoc
class _$SubjectCopyWithImpl<$Res, $Val extends Subject>
    implements $SubjectCopyWith<$Res> {
  _$SubjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectName = null,
    Object? subjectClass = null,
    Object? category = freezed,
    Object? isOriginal = null,
  }) {
    return _then(_value.copyWith(
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectClass: null == subjectClass
          ? _value.subjectClass
          : subjectClass // ignore: cast_nullable_to_non_nullable
              as int,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isOriginal: null == isOriginal
          ? _value.isOriginal
          : isOriginal // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubjectImplCopyWith<$Res> implements $SubjectCopyWith<$Res> {
  factory _$$SubjectImplCopyWith(
          _$SubjectImpl value, $Res Function(_$SubjectImpl) then) =
      __$$SubjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String subjectName,
      int subjectClass,
      String? category,
      bool isOriginal});
}

/// @nodoc
class __$$SubjectImplCopyWithImpl<$Res>
    extends _$SubjectCopyWithImpl<$Res, _$SubjectImpl>
    implements _$$SubjectImplCopyWith<$Res> {
  __$$SubjectImplCopyWithImpl(
      _$SubjectImpl _value, $Res Function(_$SubjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? subjectName = null,
    Object? subjectClass = null,
    Object? category = freezed,
    Object? isOriginal = null,
  }) {
    return _then(_$SubjectImpl(
      subjectName: null == subjectName
          ? _value.subjectName
          : subjectName // ignore: cast_nullable_to_non_nullable
              as String,
      subjectClass: null == subjectClass
          ? _value.subjectClass
          : subjectClass // ignore: cast_nullable_to_non_nullable
              as int,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isOriginal: null == isOriginal
          ? _value.isOriginal
          : isOriginal // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubjectImpl extends _Subject {
  const _$SubjectImpl(
      {required this.subjectName,
      required this.subjectClass,
      this.category,
      this.isOriginal = false})
      : super._();

  factory _$SubjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubjectImplFromJson(json);

  @override
  final String subjectName;
  @override
  final int subjectClass;
  @override
  final String? category;
  @override
  @JsonKey()
  final bool isOriginal;

  @override
  String toString() {
    return 'Subject(subjectName: $subjectName, subjectClass: $subjectClass, category: $category, isOriginal: $isOriginal)';
  }

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubjectImplCopyWith<_$SubjectImpl> get copyWith =>
      __$$SubjectImplCopyWithImpl<_$SubjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubjectImplToJson(
      this,
    );
  }
}

abstract class _Subject extends Subject {
  const factory _Subject(
      {required final String subjectName,
      required final int subjectClass,
      final String? category,
      final bool isOriginal}) = _$SubjectImpl;
  const _Subject._() : super._();

  factory _Subject.fromJson(Map<String, dynamic> json) = _$SubjectImpl.fromJson;

  @override
  String get subjectName;
  @override
  int get subjectClass;
  @override
  String? get category;
  @override
  bool get isOriginal;

  /// Create a copy of Subject
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubjectImplCopyWith<_$SubjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
