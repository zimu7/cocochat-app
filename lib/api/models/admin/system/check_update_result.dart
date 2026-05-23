class CheckUpdateResult {
  final String? buildTime;
  final String? description;
  final String? fileUrl;
  final int versionCode;
  final String? versionName;

  CheckUpdateResult({
    this.buildTime,
    this.description,
    this.fileUrl,
    required this.versionCode,
    this.versionName,
  });

  factory CheckUpdateResult.fromJson(Map<String, dynamic> json) {
    return CheckUpdateResult(
      buildTime: json['build_time'] as String?,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String?,
      versionCode: (json['version_code'] as num?)?.toInt() ?? 0,
      versionName: json['version_name'] as String?,
    );
  }
}
