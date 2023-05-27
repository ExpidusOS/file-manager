import 'package:uuid_type/uuid_type.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum FileManagerFeedbackID {
  viewLibraryGrid(key: 'view.library.grid'),
  viewLibraryList(key: 'view.library.list');

  const FileManagerFeedbackID({ required this.key });

  final String key;

  String get value => NameUuidGenerator(NameUuidGenerator.dnsNamespace).generateFromString('com.expidusos.file_manager.${key}').toString();
  SentryId get id => SentryId.fromId(value);

  @override
  String toString() => '${name}(${key},${value})=${id}';
}

enum FileManagerSettings {
  gridViewsPaths,
  showHiddenFiles,
  showHiddenLibraries,
  colorScheme,
  optInErrorReporting;

  @override
  String toString() => name;
}
