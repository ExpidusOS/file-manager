import 'package:uuid_type/uuid_type.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum FileManagerFeedbackID {
  viewLibraryGrid(key: 'view.library.grid', title: 'File browsing in a grid'),
  viewLibraryList(key: 'view.library.list', title: 'File browsing in a list'),
  viewSettings(key: 'view.settings', title: 'Settings view');

  const FileManagerFeedbackID({ required this.key, required this.title });

  final String key;
  final String title;

  String get value => NameUuidGenerator(NameUuidGenerator.dnsNamespace).generateFromString('com.expidusos.file_manager.${key}').toString();
  SentryId get id => SentryId.fromId(value);

  @override
  String toString() => '${title} (${name},${key},${value})=${id}';
}

enum FileManagerSettings {
  gridViewsPaths,
  showGridView,
  showHiddenFiles,
  showHiddenLibraries,
  colorScheme,
  optInErrorReporting;

  @override
  String toString() => name;
}
