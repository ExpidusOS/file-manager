import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/widgets.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_manager/constants.dart';

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

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      _loadSettings();
    })).catchError((error) => FlutterError.reportError(FlutterErrorDetails(exception: error)));
  }

  void _loadSettings() {
    showHiddenFiles = preferences.getBool(FileManagerSettings.showHiddenFiles.name) ?? false;
    showHiddenLibraries = preferences.getBool(FileManagerSettings.showHiddenLibraries.name) ?? false;
  }

  void _handleError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to open file: ${e.toString()}'),
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
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('imgs/icon.png'),
              title: const Text('File Manager'),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        drawer: const FileManagerDrawer(
          currentDirectory: null,
        ),
        body: ListView(
          children: [
            SwitchListTile(
              title: const Text('Show hidden files and directories'),
              value: showHiddenFiles,
              onChanged: (value) => preferences.setBool(FileManagerSettings.showHiddenFiles.name, value).then((value) {
                setState(() {
                  showHiddenFiles = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
            SwitchListTile(
              title: const Text('Show hidden libraries'),
              value: showHiddenLibraries,
              onChanged: (value) => preferences.setBool(FileManagerSettings.showHiddenLibraries.name, value).then((value) {
                setState(() {
                  showHiddenLibraries = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
            ListTile(
              title: const Text('Restore default settings'),
              onTap: () => preferences.clear().then((value) => setState(() {
                _loadSettings();
              })).catchError((error) => _handleError(context, error)),
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