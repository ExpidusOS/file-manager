import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _viewAbout(BuildContext context) => AppLocalizations.of(context)!.feedbackViewAbout;
String _viewFeedback(BuildContext context) => AppLocalizations.of(context)!.feedbackViewFeedback;
String _viewFeedbackChoice(BuildContext context) => AppLocalizations.of(context)!.feedbackViewFeedbackChoice;
String _viewLibraryGrid(BuildContext context) => AppLocalizations.of(context)!.feedbackViewLibraryGrid;
String _viewLibraryList(BuildContext context) => AppLocalizations.of(context)!.feedbackViewLibraryList;
String _viewSettings(BuildContext context) => AppLocalizations.of(context)!.feedbackViewSettings;

enum FileManagerFeedbackID implements FeedbackId<BuildContext> {
  viewAbout(key: 'view.about', onGenerateTitle: _viewAbout),
  viewFeedback(key: 'view.feedback', onGenerateTitle: _viewFeedback),
  viewFeedbackChoice(key: 'view.feedback.choise', onGenerateTitle: _viewFeedbackChoice),
  viewLibraryGrid(key: 'view.library.grid', onGenerateTitle: _viewLibraryGrid),
  viewLibraryList(key: 'view.library.list', onGenerateTitle: _viewLibraryList),
  viewSettings(key: 'view.settings', onGenerateTitle: _viewSettings);

  const FileManagerFeedbackID({ required this.key, required this.onGenerateTitle });

  final String key;
  final GenerateAppTitle onGenerateTitle;

  Future<SentryId> getId(BuildContext context) => Sentry.captureMessage('User feedback($key): ${onGenerateTitle(context)}');
  Future<String> toFutureString(BuildContext context) async => '${onGenerateTitle(context)} ($name,$key)=${await getId(context)}';
}

enum FileManagerSettings<T> implements Settings<T> {
  gridViewsPaths('gridViewsPaths', <String>[]),
  showGridView('showGridView', false),
  showHiddenFiles('showHiddenFiles', false),
  showHiddenLibraries('showHiddenLibraries', false),
  colorScheme('colorScheme', 'night'),
  optInErrorReporting('optInErrorReporting', false),
  favoritePaths('favoritePaths', <String>[]),
  firstRun('firstRun', true);

  const FileManagerSettings(this.name, this.defaultValue);

  @override
  final String name;

  final T defaultValue;
  T valueFor(SharedPreferences prefs) => (prefs.get(name) as T?) ?? defaultValue;
  Future<T> get value async => valueFor(await SharedPreferences.getInstance());

  @override
  toString() => '$name:${T.toString()}';
}
