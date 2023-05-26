import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/widgets.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({
    super.key,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late SharedPreferences preferences;
  bool showHidden = false;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      showHidden = prefs.getBool("hidden") ?? false;
    })).catchError((error) => FlutterError.reportError(FlutterErrorDetails(exception: error)));
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
              tileColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
              shape: Theme.of(context).cardTheme.shape,
              contentPadding: Theme.of(context).cardTheme.margin,
              title: const Text('Show hidden files and directories'),
              value: showHidden,
              onChanged: (value) => preferences.setBool('hidden', value).then((value) {
                setState(() {
                  showHidden = value;
                });
              }).catchError((error) => _handleError(context, error)),
            ),
          ],
        ),
      );
}