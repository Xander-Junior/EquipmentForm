import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

enum FormType { received, returned, replaced }

@freezed
class Session with _$Session {
  const factory Session({
    required String id,
    required FormType formType,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) => _$SessionFromJson(json);
}
