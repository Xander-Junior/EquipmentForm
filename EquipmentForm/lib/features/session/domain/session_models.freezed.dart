// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PartyFieldState _$PartyFieldStateFromJson(Map<String, dynamic> json) {
  return _PartyFieldState.fromJson(json);
}

/// @nodoc
mixin _$PartyFieldState {
  String get value => throw _privateConstructorUsedError;
  String? get imagePath => throw _privateConstructorUsedError;
  double? get confidence => throw _privateConstructorUsedError;
  DateTime? get capturedAt => throw _privateConstructorUsedError;

  /// Serializes this PartyFieldState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartyFieldState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartyFieldStateCopyWith<PartyFieldState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartyFieldStateCopyWith<$Res> {
  factory $PartyFieldStateCopyWith(
          PartyFieldState value, $Res Function(PartyFieldState) then) =
      _$PartyFieldStateCopyWithImpl<$Res, PartyFieldState>;
  @useResult
  $Res call(
      {String value,
      String? imagePath,
      double? confidence,
      DateTime? capturedAt});
}

/// @nodoc
class _$PartyFieldStateCopyWithImpl<$Res, $Val extends PartyFieldState>
    implements $PartyFieldStateCopyWith<$Res> {
  _$PartyFieldStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartyFieldState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? imagePath = freezed,
    Object? confidence = freezed,
    Object? capturedAt = freezed,
  }) {
    return _then(_value.copyWith(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      confidence: freezed == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double?,
      capturedAt: freezed == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartyFieldStateImplCopyWith<$Res>
    implements $PartyFieldStateCopyWith<$Res> {
  factory _$$PartyFieldStateImplCopyWith(_$PartyFieldStateImpl value,
          $Res Function(_$PartyFieldStateImpl) then) =
      __$$PartyFieldStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String value,
      String? imagePath,
      double? confidence,
      DateTime? capturedAt});
}

/// @nodoc
class __$$PartyFieldStateImplCopyWithImpl<$Res>
    extends _$PartyFieldStateCopyWithImpl<$Res, _$PartyFieldStateImpl>
    implements _$$PartyFieldStateImplCopyWith<$Res> {
  __$$PartyFieldStateImplCopyWithImpl(
      _$PartyFieldStateImpl _value, $Res Function(_$PartyFieldStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartyFieldState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? value = null,
    Object? imagePath = freezed,
    Object? confidence = freezed,
    Object? capturedAt = freezed,
  }) {
    return _then(_$PartyFieldStateImpl(
      value: null == value
          ? _value.value
          : value // ignore: cast_nullable_to_non_nullable
              as String,
      imagePath: freezed == imagePath
          ? _value.imagePath
          : imagePath // ignore: cast_nullable_to_non_nullable
              as String?,
      confidence: freezed == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double?,
      capturedAt: freezed == capturedAt
          ? _value.capturedAt
          : capturedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartyFieldStateImpl implements _PartyFieldState {
  const _$PartyFieldStateImpl(
      {this.value = '', this.imagePath, this.confidence, this.capturedAt});

  factory _$PartyFieldStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartyFieldStateImplFromJson(json);

  @override
  @JsonKey()
  final String value;
  @override
  final String? imagePath;
  @override
  final double? confidence;
  @override
  final DateTime? capturedAt;

  @override
  String toString() {
    return 'PartyFieldState(value: $value, imagePath: $imagePath, confidence: $confidence, capturedAt: $capturedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartyFieldStateImpl &&
            (identical(other.value, value) || other.value == value) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.capturedAt, capturedAt) ||
                other.capturedAt == capturedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, value, imagePath, confidence, capturedAt);

  /// Create a copy of PartyFieldState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartyFieldStateImplCopyWith<_$PartyFieldStateImpl> get copyWith =>
      __$$PartyFieldStateImplCopyWithImpl<_$PartyFieldStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartyFieldStateImplToJson(
      this,
    );
  }
}

abstract class _PartyFieldState implements PartyFieldState {
  const factory _PartyFieldState(
      {final String value,
      final String? imagePath,
      final double? confidence,
      final DateTime? capturedAt}) = _$PartyFieldStateImpl;

  factory _PartyFieldState.fromJson(Map<String, dynamic> json) =
      _$PartyFieldStateImpl.fromJson;

  @override
  String get value;
  @override
  String? get imagePath;
  @override
  double? get confidence;
  @override
  DateTime? get capturedAt;

  /// Create a copy of PartyFieldState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartyFieldStateImplCopyWith<_$PartyFieldStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PartyMemberState _$PartyMemberStateFromJson(Map<String, dynamic> json) {
  return _PartyMemberState.fromJson(json);
}

/// @nodoc
mixin _$PartyMemberState {
  PartyRole get role => throw _privateConstructorUsedError;
  Map<PartyField, PartyFieldState> get fields =>
      throw _privateConstructorUsedError;
  String? get photoPath => throw _privateConstructorUsedError;
  bool get mirrorsRequested => throw _privateConstructorUsedError;

  /// Serializes this PartyMemberState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartyMemberState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartyMemberStateCopyWith<PartyMemberState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartyMemberStateCopyWith<$Res> {
  factory $PartyMemberStateCopyWith(
          PartyMemberState value, $Res Function(PartyMemberState) then) =
      _$PartyMemberStateCopyWithImpl<$Res, PartyMemberState>;
  @useResult
  $Res call(
      {PartyRole role,
      Map<PartyField, PartyFieldState> fields,
      String? photoPath,
      bool mirrorsRequested});
}

/// @nodoc
class _$PartyMemberStateCopyWithImpl<$Res, $Val extends PartyMemberState>
    implements $PartyMemberStateCopyWith<$Res> {
  _$PartyMemberStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartyMemberState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? fields = null,
    Object? photoPath = freezed,
    Object? mirrorsRequested = null,
  }) {
    return _then(_value.copyWith(
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PartyRole,
      fields: null == fields
          ? _value.fields
          : fields // ignore: cast_nullable_to_non_nullable
              as Map<PartyField, PartyFieldState>,
      photoPath: freezed == photoPath
          ? _value.photoPath
          : photoPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mirrorsRequested: null == mirrorsRequested
          ? _value.mirrorsRequested
          : mirrorsRequested // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartyMemberStateImplCopyWith<$Res>
    implements $PartyMemberStateCopyWith<$Res> {
  factory _$$PartyMemberStateImplCopyWith(_$PartyMemberStateImpl value,
          $Res Function(_$PartyMemberStateImpl) then) =
      __$$PartyMemberStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PartyRole role,
      Map<PartyField, PartyFieldState> fields,
      String? photoPath,
      bool mirrorsRequested});
}

/// @nodoc
class __$$PartyMemberStateImplCopyWithImpl<$Res>
    extends _$PartyMemberStateCopyWithImpl<$Res, _$PartyMemberStateImpl>
    implements _$$PartyMemberStateImplCopyWith<$Res> {
  __$$PartyMemberStateImplCopyWithImpl(_$PartyMemberStateImpl _value,
      $Res Function(_$PartyMemberStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartyMemberState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? role = null,
    Object? fields = null,
    Object? photoPath = freezed,
    Object? mirrorsRequested = null,
  }) {
    return _then(_$PartyMemberStateImpl(
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as PartyRole,
      fields: null == fields
          ? _value._fields
          : fields // ignore: cast_nullable_to_non_nullable
              as Map<PartyField, PartyFieldState>,
      photoPath: freezed == photoPath
          ? _value.photoPath
          : photoPath // ignore: cast_nullable_to_non_nullable
              as String?,
      mirrorsRequested: null == mirrorsRequested
          ? _value.mirrorsRequested
          : mirrorsRequested // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartyMemberStateImpl implements _PartyMemberState {
  const _$PartyMemberStateImpl(
      {required this.role,
      final Map<PartyField, PartyFieldState> fields = const {},
      this.photoPath,
      this.mirrorsRequested = false})
      : _fields = fields;

  factory _$PartyMemberStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartyMemberStateImplFromJson(json);

  @override
  final PartyRole role;
  final Map<PartyField, PartyFieldState> _fields;
  @override
  @JsonKey()
  Map<PartyField, PartyFieldState> get fields {
    if (_fields is EqualUnmodifiableMapView) return _fields;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_fields);
  }

  @override
  final String? photoPath;
  @override
  @JsonKey()
  final bool mirrorsRequested;

  @override
  String toString() {
    return 'PartyMemberState(role: $role, fields: $fields, photoPath: $photoPath, mirrorsRequested: $mirrorsRequested)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartyMemberStateImpl &&
            (identical(other.role, role) || other.role == role) &&
            const DeepCollectionEquality().equals(other._fields, _fields) &&
            (identical(other.photoPath, photoPath) ||
                other.photoPath == photoPath) &&
            (identical(other.mirrorsRequested, mirrorsRequested) ||
                other.mirrorsRequested == mirrorsRequested));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      role,
      const DeepCollectionEquality().hash(_fields),
      photoPath,
      mirrorsRequested);

  /// Create a copy of PartyMemberState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartyMemberStateImplCopyWith<_$PartyMemberStateImpl> get copyWith =>
      __$$PartyMemberStateImplCopyWithImpl<_$PartyMemberStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartyMemberStateImplToJson(
      this,
    );
  }
}

abstract class _PartyMemberState implements PartyMemberState {
  const factory _PartyMemberState(
      {required final PartyRole role,
      final Map<PartyField, PartyFieldState> fields,
      final String? photoPath,
      final bool mirrorsRequested}) = _$PartyMemberStateImpl;

  factory _PartyMemberState.fromJson(Map<String, dynamic> json) =
      _$PartyMemberStateImpl.fromJson;

  @override
  PartyRole get role;
  @override
  Map<PartyField, PartyFieldState> get fields;
  @override
  String? get photoPath;
  @override
  bool get mirrorsRequested;

  /// Create a copy of PartyMemberState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartyMemberStateImplCopyWith<_$PartyMemberStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PartySessionState _$PartySessionStateFromJson(Map<String, dynamic> json) {
  return _PartySessionState.fromJson(json);
}

/// @nodoc
mixin _$PartySessionState {
  Map<PartyRole, PartyMemberState> get members =>
      throw _privateConstructorUsedError;

  /// Serializes this PartySessionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PartySessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PartySessionStateCopyWith<PartySessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PartySessionStateCopyWith<$Res> {
  factory $PartySessionStateCopyWith(
          PartySessionState value, $Res Function(PartySessionState) then) =
      _$PartySessionStateCopyWithImpl<$Res, PartySessionState>;
  @useResult
  $Res call({Map<PartyRole, PartyMemberState> members});
}

/// @nodoc
class _$PartySessionStateCopyWithImpl<$Res, $Val extends PartySessionState>
    implements $PartySessionStateCopyWith<$Res> {
  _$PartySessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PartySessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_value.copyWith(
      members: null == members
          ? _value.members
          : members // ignore: cast_nullable_to_non_nullable
              as Map<PartyRole, PartyMemberState>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PartySessionStateImplCopyWith<$Res>
    implements $PartySessionStateCopyWith<$Res> {
  factory _$$PartySessionStateImplCopyWith(_$PartySessionStateImpl value,
          $Res Function(_$PartySessionStateImpl) then) =
      __$$PartySessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({Map<PartyRole, PartyMemberState> members});
}

/// @nodoc
class __$$PartySessionStateImplCopyWithImpl<$Res>
    extends _$PartySessionStateCopyWithImpl<$Res, _$PartySessionStateImpl>
    implements _$$PartySessionStateImplCopyWith<$Res> {
  __$$PartySessionStateImplCopyWithImpl(_$PartySessionStateImpl _value,
      $Res Function(_$PartySessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PartySessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? members = null,
  }) {
    return _then(_$PartySessionStateImpl(
      members: null == members
          ? _value._members
          : members // ignore: cast_nullable_to_non_nullable
              as Map<PartyRole, PartyMemberState>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PartySessionStateImpl implements _PartySessionState {
  const _$PartySessionStateImpl(
      {final Map<PartyRole, PartyMemberState> members = const {}})
      : _members = members;

  factory _$PartySessionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PartySessionStateImplFromJson(json);

  final Map<PartyRole, PartyMemberState> _members;
  @override
  @JsonKey()
  Map<PartyRole, PartyMemberState> get members {
    if (_members is EqualUnmodifiableMapView) return _members;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_members);
  }

  @override
  String toString() {
    return 'PartySessionState(members: $members)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PartySessionStateImpl &&
            const DeepCollectionEquality().equals(other._members, _members));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_members));

  /// Create a copy of PartySessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PartySessionStateImplCopyWith<_$PartySessionStateImpl> get copyWith =>
      __$$PartySessionStateImplCopyWithImpl<_$PartySessionStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PartySessionStateImplToJson(
      this,
    );
  }
}

abstract class _PartySessionState implements PartySessionState {
  const factory _PartySessionState(
          {final Map<PartyRole, PartyMemberState> members}) =
      _$PartySessionStateImpl;

  factory _PartySessionState.fromJson(Map<String, dynamic> json) =
      _$PartySessionStateImpl.fromJson;

  @override
  Map<PartyRole, PartyMemberState> get members;

  /// Create a copy of PartySessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PartySessionStateImplCopyWith<_$PartySessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AccessoryState _$AccessoryStateFromJson(Map<String, dynamic> json) {
  return _AccessoryState.fromJson(json);
}

/// @nodoc
mixin _$AccessoryState {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  bool get selected => throw _privateConstructorUsedError;
  bool get suggested => throw _privateConstructorUsedError;

  /// Serializes this AccessoryState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AccessoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccessoryStateCopyWith<AccessoryState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccessoryStateCopyWith<$Res> {
  factory $AccessoryStateCopyWith(
          AccessoryState value, $Res Function(AccessoryState) then) =
      _$AccessoryStateCopyWithImpl<$Res, AccessoryState>;
  @useResult
  $Res call({String id, String label, bool selected, bool suggested});
}

/// @nodoc
class _$AccessoryStateCopyWithImpl<$Res, $Val extends AccessoryState>
    implements $AccessoryStateCopyWith<$Res> {
  _$AccessoryStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccessoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? selected = null,
    Object? suggested = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      suggested: null == suggested
          ? _value.suggested
          : suggested // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AccessoryStateImplCopyWith<$Res>
    implements $AccessoryStateCopyWith<$Res> {
  factory _$$AccessoryStateImplCopyWith(_$AccessoryStateImpl value,
          $Res Function(_$AccessoryStateImpl) then) =
      __$$AccessoryStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String label, bool selected, bool suggested});
}

/// @nodoc
class __$$AccessoryStateImplCopyWithImpl<$Res>
    extends _$AccessoryStateCopyWithImpl<$Res, _$AccessoryStateImpl>
    implements _$$AccessoryStateImplCopyWith<$Res> {
  __$$AccessoryStateImplCopyWithImpl(
      _$AccessoryStateImpl _value, $Res Function(_$AccessoryStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AccessoryState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? selected = null,
    Object? suggested = null,
  }) {
    return _then(_$AccessoryStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      selected: null == selected
          ? _value.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      suggested: null == suggested
          ? _value.suggested
          : suggested // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AccessoryStateImpl implements _AccessoryState {
  const _$AccessoryStateImpl(
      {required this.id,
      required this.label,
      this.selected = false,
      this.suggested = false});

  factory _$AccessoryStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AccessoryStateImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  @JsonKey()
  final bool selected;
  @override
  @JsonKey()
  final bool suggested;

  @override
  String toString() {
    return 'AccessoryState(id: $id, label: $label, selected: $selected, suggested: $suggested)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccessoryStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.suggested, suggested) ||
                other.suggested == suggested));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, label, selected, suggested);

  /// Create a copy of AccessoryState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccessoryStateImplCopyWith<_$AccessoryStateImpl> get copyWith =>
      __$$AccessoryStateImplCopyWithImpl<_$AccessoryStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AccessoryStateImplToJson(
      this,
    );
  }
}

abstract class _AccessoryState implements AccessoryState {
  const factory _AccessoryState(
      {required final String id,
      required final String label,
      final bool selected,
      final bool suggested}) = _$AccessoryStateImpl;

  factory _AccessoryState.fromJson(Map<String, dynamic> json) =
      _$AccessoryStateImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  bool get selected;
  @override
  bool get suggested;

  /// Create a copy of AccessoryState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccessoryStateImplCopyWith<_$AccessoryStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PrimaryDeviceState _$PrimaryDeviceStateFromJson(Map<String, dynamic> json) {
  return _PrimaryDeviceState.fromJson(json);
}

/// @nodoc
mixin _$PrimaryDeviceState {
  String get id => throw _privateConstructorUsedError;
  PrimaryDeviceType get type => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
  String get makeModel => throw _privateConstructorUsedError;
  String? get assetTag => throw _privateConstructorUsedError;
  String? get serviceTag => throw _privateConstructorUsedError;
  String? get serialNumber => throw _privateConstructorUsedError;
  String? get warrantyExpiry => throw _privateConstructorUsedError;
  String? get imei => throw _privateConstructorUsedError;
  List<AccessoryState> get accessories => throw _privateConstructorUsedError;
  bool get isReplacementOld => throw _privateConstructorUsedError;

  /// Serializes this PrimaryDeviceState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PrimaryDeviceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PrimaryDeviceStateCopyWith<PrimaryDeviceState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PrimaryDeviceStateCopyWith<$Res> {
  factory $PrimaryDeviceStateCopyWith(
          PrimaryDeviceState value, $Res Function(PrimaryDeviceState) then) =
      _$PrimaryDeviceStateCopyWithImpl<$Res, PrimaryDeviceState>;
  @useResult
  $Res call(
      {String id,
      PrimaryDeviceType type,
      @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
      String makeModel,
      String? assetTag,
      String? serviceTag,
      String? serialNumber,
      String? warrantyExpiry,
      String? imei,
      List<AccessoryState> accessories,
      bool isReplacementOld});
}

/// @nodoc
class _$PrimaryDeviceStateCopyWithImpl<$Res, $Val extends PrimaryDeviceState>
    implements $PrimaryDeviceStateCopyWith<$Res> {
  _$PrimaryDeviceStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PrimaryDeviceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? makeModel = null,
    Object? assetTag = freezed,
    Object? serviceTag = freezed,
    Object? serialNumber = freezed,
    Object? warrantyExpiry = freezed,
    Object? imei = freezed,
    Object? accessories = null,
    Object? isReplacementOld = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PrimaryDeviceType,
      makeModel: null == makeModel
          ? _value.makeModel
          : makeModel // ignore: cast_nullable_to_non_nullable
              as String,
      assetTag: freezed == assetTag
          ? _value.assetTag
          : assetTag // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceTag: freezed == serviceTag
          ? _value.serviceTag
          : serviceTag // ignore: cast_nullable_to_non_nullable
              as String?,
      serialNumber: freezed == serialNumber
          ? _value.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      warrantyExpiry: freezed == warrantyExpiry
          ? _value.warrantyExpiry
          : warrantyExpiry // ignore: cast_nullable_to_non_nullable
              as String?,
      imei: freezed == imei
          ? _value.imei
          : imei // ignore: cast_nullable_to_non_nullable
              as String?,
      accessories: null == accessories
          ? _value.accessories
          : accessories // ignore: cast_nullable_to_non_nullable
              as List<AccessoryState>,
      isReplacementOld: null == isReplacementOld
          ? _value.isReplacementOld
          : isReplacementOld // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PrimaryDeviceStateImplCopyWith<$Res>
    implements $PrimaryDeviceStateCopyWith<$Res> {
  factory _$$PrimaryDeviceStateImplCopyWith(_$PrimaryDeviceStateImpl value,
          $Res Function(_$PrimaryDeviceStateImpl) then) =
      __$$PrimaryDeviceStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      PrimaryDeviceType type,
      @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
      String makeModel,
      String? assetTag,
      String? serviceTag,
      String? serialNumber,
      String? warrantyExpiry,
      String? imei,
      List<AccessoryState> accessories,
      bool isReplacementOld});
}

/// @nodoc
class __$$PrimaryDeviceStateImplCopyWithImpl<$Res>
    extends _$PrimaryDeviceStateCopyWithImpl<$Res, _$PrimaryDeviceStateImpl>
    implements _$$PrimaryDeviceStateImplCopyWith<$Res> {
  __$$PrimaryDeviceStateImplCopyWithImpl(_$PrimaryDeviceStateImpl _value,
      $Res Function(_$PrimaryDeviceStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of PrimaryDeviceState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? makeModel = null,
    Object? assetTag = freezed,
    Object? serviceTag = freezed,
    Object? serialNumber = freezed,
    Object? warrantyExpiry = freezed,
    Object? imei = freezed,
    Object? accessories = null,
    Object? isReplacementOld = null,
  }) {
    return _then(_$PrimaryDeviceStateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as PrimaryDeviceType,
      makeModel: null == makeModel
          ? _value.makeModel
          : makeModel // ignore: cast_nullable_to_non_nullable
              as String,
      assetTag: freezed == assetTag
          ? _value.assetTag
          : assetTag // ignore: cast_nullable_to_non_nullable
              as String?,
      serviceTag: freezed == serviceTag
          ? _value.serviceTag
          : serviceTag // ignore: cast_nullable_to_non_nullable
              as String?,
      serialNumber: freezed == serialNumber
          ? _value.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      warrantyExpiry: freezed == warrantyExpiry
          ? _value.warrantyExpiry
          : warrantyExpiry // ignore: cast_nullable_to_non_nullable
              as String?,
      imei: freezed == imei
          ? _value.imei
          : imei // ignore: cast_nullable_to_non_nullable
              as String?,
      accessories: null == accessories
          ? _value._accessories
          : accessories // ignore: cast_nullable_to_non_nullable
              as List<AccessoryState>,
      isReplacementOld: null == isReplacementOld
          ? _value.isReplacementOld
          : isReplacementOld // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PrimaryDeviceStateImpl implements _PrimaryDeviceState {
  const _$PrimaryDeviceStateImpl(
      {required this.id,
      required this.type,
      @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
      required this.makeModel,
      this.assetTag,
      this.serviceTag,
      this.serialNumber,
      this.warrantyExpiry,
      this.imei,
      final List<AccessoryState> accessories = const <AccessoryState>[],
      this.isReplacementOld = false})
      : _accessories = accessories;

  factory _$PrimaryDeviceStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PrimaryDeviceStateImplFromJson(json);

  @override
  final String id;
  @override
  final PrimaryDeviceType type;
  @override
  @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
  final String makeModel;
  @override
  final String? assetTag;
  @override
  final String? serviceTag;
  @override
  final String? serialNumber;
  @override
  final String? warrantyExpiry;
  @override
  final String? imei;
  final List<AccessoryState> _accessories;
  @override
  @JsonKey()
  List<AccessoryState> get accessories {
    if (_accessories is EqualUnmodifiableListView) return _accessories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_accessories);
  }

  @override
  @JsonKey()
  final bool isReplacementOld;

  @override
  String toString() {
    return 'PrimaryDeviceState(id: $id, type: $type, makeModel: $makeModel, assetTag: $assetTag, serviceTag: $serviceTag, serialNumber: $serialNumber, warrantyExpiry: $warrantyExpiry, imei: $imei, accessories: $accessories, isReplacementOld: $isReplacementOld)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PrimaryDeviceStateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.makeModel, makeModel) ||
                other.makeModel == makeModel) &&
            (identical(other.assetTag, assetTag) ||
                other.assetTag == assetTag) &&
            (identical(other.serviceTag, serviceTag) ||
                other.serviceTag == serviceTag) &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.warrantyExpiry, warrantyExpiry) ||
                other.warrantyExpiry == warrantyExpiry) &&
            (identical(other.imei, imei) || other.imei == imei) &&
            const DeepCollectionEquality()
                .equals(other._accessories, _accessories) &&
            (identical(other.isReplacementOld, isReplacementOld) ||
                other.isReplacementOld == isReplacementOld));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      makeModel,
      assetTag,
      serviceTag,
      serialNumber,
      warrantyExpiry,
      imei,
      const DeepCollectionEquality().hash(_accessories),
      isReplacementOld);

  /// Create a copy of PrimaryDeviceState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PrimaryDeviceStateImplCopyWith<_$PrimaryDeviceStateImpl> get copyWith =>
      __$$PrimaryDeviceStateImplCopyWithImpl<_$PrimaryDeviceStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PrimaryDeviceStateImplToJson(
      this,
    );
  }
}

abstract class _PrimaryDeviceState implements PrimaryDeviceState {
  const factory _PrimaryDeviceState(
      {required final String id,
      required final PrimaryDeviceType type,
      @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
      required final String makeModel,
      final String? assetTag,
      final String? serviceTag,
      final String? serialNumber,
      final String? warrantyExpiry,
      final String? imei,
      final List<AccessoryState> accessories,
      final bool isReplacementOld}) = _$PrimaryDeviceStateImpl;

  factory _PrimaryDeviceState.fromJson(Map<String, dynamic> json) =
      _$PrimaryDeviceStateImpl.fromJson;

  @override
  String get id;
  @override
  PrimaryDeviceType get type;
  @override
  @JsonKey(fromJson: _makeModelFromJson, toJson: _makeModelToJson)
  String get makeModel;
  @override
  String? get assetTag;
  @override
  String? get serviceTag;
  @override
  String? get serialNumber;
  @override
  String? get warrantyExpiry;
  @override
  String? get imei;
  @override
  List<AccessoryState> get accessories;
  @override
  bool get isReplacementOld;

  /// Create a copy of PrimaryDeviceState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PrimaryDeviceStateImplCopyWith<_$PrimaryDeviceStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EquipmentSessionState _$EquipmentSessionStateFromJson(
    Map<String, dynamic> json) {
  return _EquipmentSessionState.fromJson(json);
}

/// @nodoc
mixin _$EquipmentSessionState {
  List<PrimaryDeviceState> get primaries => throw _privateConstructorUsedError;

  /// Serializes this EquipmentSessionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EquipmentSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EquipmentSessionStateCopyWith<EquipmentSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EquipmentSessionStateCopyWith<$Res> {
  factory $EquipmentSessionStateCopyWith(EquipmentSessionState value,
          $Res Function(EquipmentSessionState) then) =
      _$EquipmentSessionStateCopyWithImpl<$Res, EquipmentSessionState>;
  @useResult
  $Res call({List<PrimaryDeviceState> primaries});
}

/// @nodoc
class _$EquipmentSessionStateCopyWithImpl<$Res,
        $Val extends EquipmentSessionState>
    implements $EquipmentSessionStateCopyWith<$Res> {
  _$EquipmentSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EquipmentSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primaries = null,
  }) {
    return _then(_value.copyWith(
      primaries: null == primaries
          ? _value.primaries
          : primaries // ignore: cast_nullable_to_non_nullable
              as List<PrimaryDeviceState>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EquipmentSessionStateImplCopyWith<$Res>
    implements $EquipmentSessionStateCopyWith<$Res> {
  factory _$$EquipmentSessionStateImplCopyWith(
          _$EquipmentSessionStateImpl value,
          $Res Function(_$EquipmentSessionStateImpl) then) =
      __$$EquipmentSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<PrimaryDeviceState> primaries});
}

/// @nodoc
class __$$EquipmentSessionStateImplCopyWithImpl<$Res>
    extends _$EquipmentSessionStateCopyWithImpl<$Res,
        _$EquipmentSessionStateImpl>
    implements _$$EquipmentSessionStateImplCopyWith<$Res> {
  __$$EquipmentSessionStateImplCopyWithImpl(_$EquipmentSessionStateImpl _value,
      $Res Function(_$EquipmentSessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of EquipmentSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? primaries = null,
  }) {
    return _then(_$EquipmentSessionStateImpl(
      primaries: null == primaries
          ? _value._primaries
          : primaries // ignore: cast_nullable_to_non_nullable
              as List<PrimaryDeviceState>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EquipmentSessionStateImpl implements _EquipmentSessionState {
  const _$EquipmentSessionStateImpl(
      {final List<PrimaryDeviceState> primaries = const <PrimaryDeviceState>[]})
      : _primaries = primaries;

  factory _$EquipmentSessionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$EquipmentSessionStateImplFromJson(json);

  final List<PrimaryDeviceState> _primaries;
  @override
  @JsonKey()
  List<PrimaryDeviceState> get primaries {
    if (_primaries is EqualUnmodifiableListView) return _primaries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_primaries);
  }

  @override
  String toString() {
    return 'EquipmentSessionState(primaries: $primaries)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EquipmentSessionStateImpl &&
            const DeepCollectionEquality()
                .equals(other._primaries, _primaries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, const DeepCollectionEquality().hash(_primaries));

  /// Create a copy of EquipmentSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EquipmentSessionStateImplCopyWith<_$EquipmentSessionStateImpl>
      get copyWith => __$$EquipmentSessionStateImplCopyWithImpl<
          _$EquipmentSessionStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EquipmentSessionStateImplToJson(
      this,
    );
  }
}

abstract class _EquipmentSessionState implements EquipmentSessionState {
  const factory _EquipmentSessionState(
      {final List<PrimaryDeviceState> primaries}) = _$EquipmentSessionStateImpl;

  factory _EquipmentSessionState.fromJson(Map<String, dynamic> json) =
      _$EquipmentSessionStateImpl.fromJson;

  @override
  List<PrimaryDeviceState> get primaries;

  /// Create a copy of EquipmentSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EquipmentSessionStateImplCopyWith<_$EquipmentSessionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}

WorkflowSessionState _$WorkflowSessionStateFromJson(Map<String, dynamic> json) {
  return _WorkflowSessionState.fromJson(json);
}

/// @nodoc
mixin _$WorkflowSessionState {
  FormType get formType => throw _privateConstructorUsedError;
  LocationCode? get location => throw _privateConstructorUsedError;
  DateTime? get dateReceived => throw _privateConstructorUsedError;
  DateTime? get dateReturned => throw _privateConstructorUsedError;
  bool get dataHandlingConfirmed => throw _privateConstructorUsedError;

  /// Serializes this WorkflowSessionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WorkflowSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WorkflowSessionStateCopyWith<WorkflowSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkflowSessionStateCopyWith<$Res> {
  factory $WorkflowSessionStateCopyWith(WorkflowSessionState value,
          $Res Function(WorkflowSessionState) then) =
      _$WorkflowSessionStateCopyWithImpl<$Res, WorkflowSessionState>;
  @useResult
  $Res call(
      {FormType formType,
      LocationCode? location,
      DateTime? dateReceived,
      DateTime? dateReturned,
      bool dataHandlingConfirmed});
}

/// @nodoc
class _$WorkflowSessionStateCopyWithImpl<$Res,
        $Val extends WorkflowSessionState>
    implements $WorkflowSessionStateCopyWith<$Res> {
  _$WorkflowSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WorkflowSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formType = null,
    Object? location = freezed,
    Object? dateReceived = freezed,
    Object? dateReturned = freezed,
    Object? dataHandlingConfirmed = null,
  }) {
    return _then(_value.copyWith(
      formType: null == formType
          ? _value.formType
          : formType // ignore: cast_nullable_to_non_nullable
              as FormType,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as LocationCode?,
      dateReceived: freezed == dateReceived
          ? _value.dateReceived
          : dateReceived // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateReturned: freezed == dateReturned
          ? _value.dateReturned
          : dateReturned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dataHandlingConfirmed: null == dataHandlingConfirmed
          ? _value.dataHandlingConfirmed
          : dataHandlingConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkflowSessionStateImplCopyWith<$Res>
    implements $WorkflowSessionStateCopyWith<$Res> {
  factory _$$WorkflowSessionStateImplCopyWith(_$WorkflowSessionStateImpl value,
          $Res Function(_$WorkflowSessionStateImpl) then) =
      __$$WorkflowSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {FormType formType,
      LocationCode? location,
      DateTime? dateReceived,
      DateTime? dateReturned,
      bool dataHandlingConfirmed});
}

/// @nodoc
class __$$WorkflowSessionStateImplCopyWithImpl<$Res>
    extends _$WorkflowSessionStateCopyWithImpl<$Res, _$WorkflowSessionStateImpl>
    implements _$$WorkflowSessionStateImplCopyWith<$Res> {
  __$$WorkflowSessionStateImplCopyWithImpl(_$WorkflowSessionStateImpl _value,
      $Res Function(_$WorkflowSessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of WorkflowSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? formType = null,
    Object? location = freezed,
    Object? dateReceived = freezed,
    Object? dateReturned = freezed,
    Object? dataHandlingConfirmed = null,
  }) {
    return _then(_$WorkflowSessionStateImpl(
      formType: null == formType
          ? _value.formType
          : formType // ignore: cast_nullable_to_non_nullable
              as FormType,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as LocationCode?,
      dateReceived: freezed == dateReceived
          ? _value.dateReceived
          : dateReceived // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateReturned: freezed == dateReturned
          ? _value.dateReturned
          : dateReturned // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dataHandlingConfirmed: null == dataHandlingConfirmed
          ? _value.dataHandlingConfirmed
          : dataHandlingConfirmed // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkflowSessionStateImpl implements _WorkflowSessionState {
  const _$WorkflowSessionStateImpl(
      {required this.formType,
      this.location,
      this.dateReceived,
      this.dateReturned,
      this.dataHandlingConfirmed = false});

  factory _$WorkflowSessionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkflowSessionStateImplFromJson(json);

  @override
  final FormType formType;
  @override
  final LocationCode? location;
  @override
  final DateTime? dateReceived;
  @override
  final DateTime? dateReturned;
  @override
  @JsonKey()
  final bool dataHandlingConfirmed;

  @override
  String toString() {
    return 'WorkflowSessionState(formType: $formType, location: $location, dateReceived: $dateReceived, dateReturned: $dateReturned, dataHandlingConfirmed: $dataHandlingConfirmed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkflowSessionStateImpl &&
            (identical(other.formType, formType) ||
                other.formType == formType) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.dateReceived, dateReceived) ||
                other.dateReceived == dateReceived) &&
            (identical(other.dateReturned, dateReturned) ||
                other.dateReturned == dateReturned) &&
            (identical(other.dataHandlingConfirmed, dataHandlingConfirmed) ||
                other.dataHandlingConfirmed == dataHandlingConfirmed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, formType, location, dateReceived,
      dateReturned, dataHandlingConfirmed);

  /// Create a copy of WorkflowSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkflowSessionStateImplCopyWith<_$WorkflowSessionStateImpl>
      get copyWith =>
          __$$WorkflowSessionStateImplCopyWithImpl<_$WorkflowSessionStateImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkflowSessionStateImplToJson(
      this,
    );
  }
}

abstract class _WorkflowSessionState implements WorkflowSessionState {
  const factory _WorkflowSessionState(
      {required final FormType formType,
      final LocationCode? location,
      final DateTime? dateReceived,
      final DateTime? dateReturned,
      final bool dataHandlingConfirmed}) = _$WorkflowSessionStateImpl;

  factory _WorkflowSessionState.fromJson(Map<String, dynamic> json) =
      _$WorkflowSessionStateImpl.fromJson;

  @override
  FormType get formType;
  @override
  LocationCode? get location;
  @override
  DateTime? get dateReceived;
  @override
  DateTime? get dateReturned;
  @override
  bool get dataHandlingConfirmed;

  /// Create a copy of WorkflowSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WorkflowSessionStateImplCopyWith<_$WorkflowSessionStateImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AppSessionState _$AppSessionStateFromJson(Map<String, dynamic> json) {
  return _AppSessionState.fromJson(json);
}

/// @nodoc
mixin _$AppSessionState {
  PartySessionState get party => throw _privateConstructorUsedError;
  EquipmentSessionState get equipment => throw _privateConstructorUsedError;
  WorkflowSessionState get workflow => throw _privateConstructorUsedError;

  /// Serializes this AppSessionState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AppSessionStateCopyWith<AppSessionState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppSessionStateCopyWith<$Res> {
  factory $AppSessionStateCopyWith(
          AppSessionState value, $Res Function(AppSessionState) then) =
      _$AppSessionStateCopyWithImpl<$Res, AppSessionState>;
  @useResult
  $Res call(
      {PartySessionState party,
      EquipmentSessionState equipment,
      WorkflowSessionState workflow});

  $PartySessionStateCopyWith<$Res> get party;
  $EquipmentSessionStateCopyWith<$Res> get equipment;
  $WorkflowSessionStateCopyWith<$Res> get workflow;
}

/// @nodoc
class _$AppSessionStateCopyWithImpl<$Res, $Val extends AppSessionState>
    implements $AppSessionStateCopyWith<$Res> {
  _$AppSessionStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? party = null,
    Object? equipment = null,
    Object? workflow = null,
  }) {
    return _then(_value.copyWith(
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PartySessionState,
      equipment: null == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as EquipmentSessionState,
      workflow: null == workflow
          ? _value.workflow
          : workflow // ignore: cast_nullable_to_non_nullable
              as WorkflowSessionState,
    ) as $Val);
  }

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PartySessionStateCopyWith<$Res> get party {
    return $PartySessionStateCopyWith<$Res>(_value.party, (value) {
      return _then(_value.copyWith(party: value) as $Val);
    });
  }

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $EquipmentSessionStateCopyWith<$Res> get equipment {
    return $EquipmentSessionStateCopyWith<$Res>(_value.equipment, (value) {
      return _then(_value.copyWith(equipment: value) as $Val);
    });
  }

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WorkflowSessionStateCopyWith<$Res> get workflow {
    return $WorkflowSessionStateCopyWith<$Res>(_value.workflow, (value) {
      return _then(_value.copyWith(workflow: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AppSessionStateImplCopyWith<$Res>
    implements $AppSessionStateCopyWith<$Res> {
  factory _$$AppSessionStateImplCopyWith(_$AppSessionStateImpl value,
          $Res Function(_$AppSessionStateImpl) then) =
      __$$AppSessionStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {PartySessionState party,
      EquipmentSessionState equipment,
      WorkflowSessionState workflow});

  @override
  $PartySessionStateCopyWith<$Res> get party;
  @override
  $EquipmentSessionStateCopyWith<$Res> get equipment;
  @override
  $WorkflowSessionStateCopyWith<$Res> get workflow;
}

/// @nodoc
class __$$AppSessionStateImplCopyWithImpl<$Res>
    extends _$AppSessionStateCopyWithImpl<$Res, _$AppSessionStateImpl>
    implements _$$AppSessionStateImplCopyWith<$Res> {
  __$$AppSessionStateImplCopyWithImpl(
      _$AppSessionStateImpl _value, $Res Function(_$AppSessionStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? party = null,
    Object? equipment = null,
    Object? workflow = null,
  }) {
    return _then(_$AppSessionStateImpl(
      party: null == party
          ? _value.party
          : party // ignore: cast_nullable_to_non_nullable
              as PartySessionState,
      equipment: null == equipment
          ? _value.equipment
          : equipment // ignore: cast_nullable_to_non_nullable
              as EquipmentSessionState,
      workflow: null == workflow
          ? _value.workflow
          : workflow // ignore: cast_nullable_to_non_nullable
              as WorkflowSessionState,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppSessionStateImpl implements _AppSessionState {
  const _$AppSessionStateImpl(
      {required this.party, required this.equipment, required this.workflow});

  factory _$AppSessionStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppSessionStateImplFromJson(json);

  @override
  final PartySessionState party;
  @override
  final EquipmentSessionState equipment;
  @override
  final WorkflowSessionState workflow;

  @override
  String toString() {
    return 'AppSessionState(party: $party, equipment: $equipment, workflow: $workflow)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppSessionStateImpl &&
            (identical(other.party, party) || other.party == party) &&
            (identical(other.equipment, equipment) ||
                other.equipment == equipment) &&
            (identical(other.workflow, workflow) ||
                other.workflow == workflow));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, party, equipment, workflow);

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AppSessionStateImplCopyWith<_$AppSessionStateImpl> get copyWith =>
      __$$AppSessionStateImplCopyWithImpl<_$AppSessionStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppSessionStateImplToJson(
      this,
    );
  }
}

abstract class _AppSessionState implements AppSessionState {
  const factory _AppSessionState(
      {required final PartySessionState party,
      required final EquipmentSessionState equipment,
      required final WorkflowSessionState workflow}) = _$AppSessionStateImpl;

  factory _AppSessionState.fromJson(Map<String, dynamic> json) =
      _$AppSessionStateImpl.fromJson;

  @override
  PartySessionState get party;
  @override
  EquipmentSessionState get equipment;
  @override
  WorkflowSessionState get workflow;

  /// Create a copy of AppSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AppSessionStateImplCopyWith<_$AppSessionStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
