enum FileManagerBuildConfig {
  sentryDsn;

  String get value => String.fromEnvironment(name);
  bool get isSet => value.isNotEmpty;
}

enum FileManagerSettings {
  showHiddenFiles,
  showHiddenLibraries,
  colorScheme,
  optInErrorReporting;

  @override
  String toString() => name;
}