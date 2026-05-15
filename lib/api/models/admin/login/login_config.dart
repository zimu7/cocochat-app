import 'package:json_annotation/json_annotation.dart';
import 'package:cocochat_app/api/models/admin/login/oidc_info.dart';

part 'login_config.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class AdminLoginConfig {
  String whoCanSignUp;
  bool password;
  bool magicLink;
  List<OidcInfo> oidc;
  bool thirdParty;

  AdminLoginConfig(
      {required this.whoCanSignUp,
      required this.password,
      required this.magicLink,
      required this.oidc,
      required this.thirdParty});

  factory AdminLoginConfig.fromJson(Map<String, dynamic> json) =>
      _$AdminLoginConfigFromJson(json);

  Map<String, dynamic> toJson() => _$AdminLoginConfigToJson(this);
}
