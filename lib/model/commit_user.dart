import 'package:json_annotation/json_annotation.dart';

part 'commit_user.g.dart';

/// Model class for a committer of a commit.
@JsonSerializable()
class CommitUser {
  CommitUser(this.name, this.email);

  final String? name;
  final String? email;

  factory CommitUser.fromJson(Map<String, dynamic> input) =>
      _$CommitUserFromJson(input);

  Map<String, dynamic> toJson() => _$CommitUserToJson(this);
}
