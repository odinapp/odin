import 'package:json_annotation/json_annotation.dart';
import 'package:odin/model/commit_user.dart';

part 'create_file.g.dart';

@JsonSerializable()
class CreateFile {
  CreateFile({this.path, this.content, this.message, this.branch, this.committer});

  String? path;
  String? message;
  String? content;
  String? branch;
  CommitUser? committer;

  factory CreateFile.fromJson(Map<String, dynamic> json) => _$CreateFileFromJson(json);

  Map<String, dynamic> toJson() => _$CreateFileToJson(this);
}
