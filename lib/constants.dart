enum FileManagerBuildConfig {
  sentryDsn(key: 'SENTRY_DSN');

  const FileManagerBuildConfig({ required this.key });

  final String key;

  String get value => String.fromEnvironment(key);
  bool get isSet => value.isNotEmpty;

  @override
  String toString() => '${key}=${value}';
}

enum FileManagerSettings {
  showHiddenFiles,
  showHiddenLibraries,
  colorScheme,
  optInErrorReporting;

  @override
  String toString() => name;
}