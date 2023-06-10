import 'package:file_manager/logic/error.dart';
import 'package:file_manager/main.dart';
import 'package:file_manager/views.dart';
import 'package:flutter/material.dart' hide ColorScheme, Scaffold;
import 'package:libtokyo/libtokyo.dart' show ColorScheme;
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_manager/constants.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SharedPreferences preferences;
  bool showHiddenFiles = false;
  bool showHiddenLibraries = false;
  bool showGridView = false;
  bool optInErrorReporting = false;
  ColorScheme colorScheme = ColorScheme.night;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      _loadSettings();
    })).catchError((error, trace) => handleError(error, trace: trace));
  }

  void _loadSettings() {
    showHiddenFiles = preferences.getBool(FileManagerSettings.showHiddenFiles.name) ?? false;
    showHiddenLibraries = preferences.getBool(FileManagerSettings.showHiddenLibraries.name) ?? false;
    showGridView = preferences.getBool(FileManagerSettings.showGridView.name) ?? false;
    optInErrorReporting = preferences.getBool(FileManagerSettings.optInErrorReporting.name) ?? false;
    colorScheme = ColorScheme.values.asNameMap()[preferences.getString(FileManagerSettings.colorScheme.name) ?? 'night']!;
  }

  void _handleError(BuildContext context, Object e) {
    print(e);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.genericErrorMessage(e.toString())),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? WindowBar(
          leading: Image.asset('assets/imgs/icon.png'),
          title: Text(AppLocalizations.of(context)!.applicationTitle),
        ) : null,
        appBar: AppBar(
          leading: const DrawerWithClose(),
          leadingWidth: Navigator.of(context).canPop() ? 100.0 : 56.0,
          title: Text(AppLocalizations.of(context)!.viewSettings),
        ),
        drawer: const FileManagerDrawer(
          currentDirectory: null,
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.settingsShowHiddenFiles),
              value: showHiddenFiles,
              onChanged: (value) => preferences.setBool(FileManagerSettings.showHiddenFiles.name, value).then((v) {
                setState(() {
                  showHiddenFiles = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.settingsShowHiddenLibraries),
              value: showHiddenLibraries,
              onChanged: (value) => preferences.setBool(FileManagerSettings.showHiddenLibraries.name, value).then((v) {
                setState(() {
                  showHiddenLibraries = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
            SwitchListTile(
              title: Text(AppLocalizations.of(context)!.settingsShowGridView),
              value: showGridView,
              onChanged: (value) => preferences.setBool(FileManagerSettings.showGridView.name, value).then((v) {
                setState(() {
                  showGridView = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.settingsTheme),
              onTap: () => showDialog(
                context: context,
                builder: (context) => Dialog(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      children: [
                        RadioListTile(
                          title: const Text('Storm'),
                          value: ColorScheme.storm,
                          groupValue: colorScheme,
                          onChanged: (value) => preferences.setString(FileManagerSettings.colorScheme.name, value!.name).then((v) {
                            setState(() {
                              colorScheme = value;
                              FileManagerApp.reload(context);
                            });
                          }).catchError((error) => _handleError(context, error)),
                        ),
                        RadioListTile(
                          title: const Text('Night'),
                          value: ColorScheme.night,
                          groupValue: colorScheme,
                          onChanged: (value) => preferences.setString(FileManagerSettings.colorScheme.name, value!.name).then((v) {
                            setState(() {
                              colorScheme = value;
                              FileManagerApp.reload(context);
                            });
                          }).catchError((error) => _handleError(context, error)),
                        ),
                        RadioListTile(
                          title: const Text('Moon'),
                          value: ColorScheme.moon,
                          groupValue: colorScheme,
                          onChanged: (value) => preferences.setString(FileManagerSettings.colorScheme.name, value!.name).then((v) {
                            setState(() {
                              colorScheme = value;
                              FileManagerApp.reload(context);
                            });
                          }).catchError((error) => _handleError(context, error)),
                        ),
                        RadioListTile(
                          title: const Text('Day'),
                          value: ColorScheme.day,
                          groupValue: colorScheme,
                          onChanged: (value) => preferences.setString(FileManagerSettings.colorScheme.name, value!.name).then((v) {
                            setState(() {
                              colorScheme = value;
                              FileManagerApp.reload(context);
                            });
                          }).catchError((error) => _handleError(context, error)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ...(const String.fromEnvironment('SENTRY_DSN', defaultValue: '').isNotEmpty ? [
              SwitchListTile(
                title: Text(AppLocalizations.of(context)!.settingsOptInErrorReporting),
                subtitle: Text(AppLocalizations.of(context)!.settingsOptInErrorReportingSubtitle),
                value: optInErrorReporting,
                onChanged: (value) => preferences.setBool(FileManagerSettings.optInErrorReporting.name, value).then((v) {
                  setState(() {
                    optInErrorReporting = value;
                  });
                }).catchError((error) => _handleError(context, error)),
              ),
            ] : []),
            const Divider(),
            ...(const String.fromEnvironment('SENTRY_DSN', defaultValue: '').isNotEmpty && FileManagerApp.isSentryOnContext(context) ? [
              ListTile(
                title: Text(AppLocalizations.of(context)!.feedbackSend),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const FeedbackChoice(),
                    settings: const RouteSettings(name: 'FeedbackChoice'),
                  )
                ),
              ),
            ] : []),
            ListTile(
              title: Text(AppLocalizations.of(context)!.settingsRestoreDefaults),
              onTap: () => preferences.clear().then((value) => setState(() {
                _loadSettings();
              })).catchError((error) => _handleError(context, error)),
            ),
            const Divider(),
            ListTile(
              title: Text(AppLocalizations.of(context)!.viewPrivacy),
              onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const Privacy(),
                    settings: const RouteSettings(name: 'Privacy'),
                  )
              ),
            ),
            ListTile(
              title: Text(AppLocalizations.of(context)!.viewAbout),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const About(),
                  settings: const RouteSettings(name: 'About'),
                )
              ),
            ),
          ].map((child) => child is Divider ? child : ListTileTheme(
            tileColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
            shape: Theme.of(context).cardTheme.shape,
            contentPadding: Theme.of(context).cardTheme.margin,
            child: child
          )).toList(),
        ),
      );
}