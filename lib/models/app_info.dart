class AppInfo {
  final String name;
  final String package;
  final String version;
  final String installed;
  final String updated;
  final String? iconBase64;

  AppInfo(this.name, this.package, this.version, this.installed, this.updated, [this.iconBase64]);

  Map<String, dynamic> toJson() => {
    'name': name,
    'package': package,
    'version': version,
    'installed': installed,
    'updated': updated,
    'iconBase64': iconBase64,
  };

  factory AppInfo.fromJson(Map<String, dynamic> json) =>
      AppInfo(json['name'], json['package'], json['version'], json['installed'], json['updated'], json['iconBase64']);
}
