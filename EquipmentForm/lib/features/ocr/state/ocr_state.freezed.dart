// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ocr_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OcrState {
  bool get isProcessing => throw _privateConstructorUsedError;
  OcrResult? get result => throw _privateConstructorUsedError;
  String? get errorMessage => throw _privateConstructorUsedError;
  bool get lastUsedPreprocessing => throw _privateConstructorUsedError;

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OcrStateCopyWith<OcrState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OcrStateCopyWith<$Res> {
  factory $OcrStateCopyWith(OcrState value, $Res Function(OcrState) then) =
      _$OcrStateCopyWithImpl<$Res, OcrState>;
  @useResult
  $Res call(
      {bool isProcessing,
      OcrResult? result,
      String? errorMessage,
      bool lastUsedPreprocessing});

  $OcrResultCopyWith<$Res>? get result;
}

/// @nodoc
class _$OcrStateCopyWithImpl<$Res, $Val extends OcrState>
    implements $OcrStateCopyWith<$Res> {
  _$OcrStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isProcessing = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
    Object? lastUsedPreprocessing = null,
  }) {
    return _then(_value.copyWith(
      isProcessing: null == isProcessing
          ? _value.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as OcrResult?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUsedPreprocessing: null == lastUsedPreprocessing
          ? _value.lastUsedPreprocessing
          : lastUsedPreprocessing // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $OcrResultCopyWith<$Res>? get result {
    if (_value.result == null) {
      return null;
    }

    return $OcrResultCopyWith<$Res>(_value.result!, (value) {
      return _then(_value.copyWith(result: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$OcrStateImplCopyWith<$Res>
    implements $OcrStateCopyWith<$Res> {
  factory _$$OcrStateImplCopyWith(
          _$OcrStateImpl value, $Res Function(_$OcrStateImpl) then) =
      __$$OcrStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isProcessing,
      OcrResult? result,
      String? errorMessage,
      bool lastUsedPreprocessing});

  @override
  $OcrResultCopyWith<$Res>? get result;
}

/// @nodoc
class __$$OcrStateImplCopyWithImpl<$Res>
    extends _$OcrStateCopyWithImpl<$Res, _$OcrStateImpl>
    implements _$$OcrStateImplCopyWith<$Res> {
  __$$OcrStateImplCopyWithImpl(
      _$OcrStateImpl _value, $Res Function(_$OcrStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isProcessing = null,
    Object? result = freezed,
    Object? errorMessage = freezed,
    Object? lastUsedPreprocessing = null,
  }) {
    return _then(_$OcrStateImpl(
      isProcessing: null == isProcessing
          ? _value.isProcessing
          : isProcessing // ignore: cast_nullable_to_non_nullable
              as bool,
      result: freezed == result
          ? _value.result
          : result // ignore: cast_nullable_to_non_nullable
              as OcrResult?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      lastUsedPreprocessing: null == lastUsedPreprocessing
          ? _value.lastUsedPreprocessing
          : lastUsedPreprocessing // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$OcrStateImpl implements _OcrState {
  const _$OcrStateImpl(
      {this.isProcessing = false,
      this.result,
      this.errorMessage,
      this.lastUsedPreprocessing = false});

  @override
  @JsonKey()
  final bool isProcessing;
  @override
  final OcrResult? result;
  @override
  final String? errorMessage;
  @override
  @JsonKey()
  final bool lastUsedPreprocessing;

  @override
  String toString() {
    return 'OcrState(isProcessing: $isProcessing, result: $result, errorMessage: $errorMessage, lastUsedPreprocessing: $lastUsedPreprocessing)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OcrStateImpl &&
            (identical(other.isProcessing, isProcessing) ||
                other.isProcessing == isProcessing) &&
            (identical(other.result, result) || other.result == result) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.lastUsedPreprocessing, lastUsedPreprocessing) ||
                other.lastUsedPreprocessing == lastUsedPreprocessing));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, isProcessing, result, errorMessage, lastUsedPreprocessing);

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OcrStateImplCopyWith<_$OcrStateImpl> get copyWith =>
      __$$OcrStateImplCopyWithImpl<_$OcrStateImpl>(this, _$identity);
}

abstract class _OcrState implements OcrState {
  const factory _OcrState(
      {final bool isProcessing,
      final OcrResult? result,
      final String? errorMessage,
      final bool lastUsedPreprocessing}) = _$OcrStateImpl;

  @override
  bool get isProcessing;
  @override
  OcrResult? get result;
  @override
  String? get errorMessage;
  @override
  bool get lastUsedPreprocessing;

  /// Create a copy of OcrState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OcrStateImplCopyWith<_$OcrStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
