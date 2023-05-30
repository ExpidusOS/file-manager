import 'package:uuid_type/uuid_type.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

enum FileManagerFeedbackID {
  viewAbout(key: 'view.about', title: 'Application about'),
  viewFeedback(key: 'view.feedback', title: 'Feedback submission view'),
  viewFeedbackChoice(key: 'view.feedback.choise', title: 'Feedback choice list'),
  viewLibraryGrid(key: 'view.library.grid', title: 'File browsing in a grid'),
  viewLibraryList(key: 'view.library.list', title: 'File browsing in a list'),
  viewSettings(key: 'view.settings', title: 'Settings view');

  const FileManagerFeedbackID({ required this.key, required this.title });

  final String key;
  final String title;

  Future<SentryId> get id => Sentry.captureMessage('User feedback($key): $title');
  Future<String> toFutureString() async => '$title ($name,$key)=${await id}';
}

enum FileManagerSettings {
  gridViewsPaths,
  showGridView,
  showHiddenFiles,
  showHiddenLibraries,
  colorScheme,
  optInErrorReporting,
  favoritePaths;

  @override
  String toString() => name;
}
