import 'package:file_manager/constants.dart';
import 'package:file_manager/logic/error.dart';
import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/logic.dart';
import 'package:file_manager/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'dart:io' as io;

class LibraryView extends StatefulWidget {
  const LibraryView({
    super.key,
    this.currentDirectory,
  });

  final io.Directory? currentDirectory;

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> with FileManagerLogic<LibraryView> {
  late SharedPreferences preferences;
  bool gridView = false;
  bool showHiddenFiles = false;
  Key key = UniqueKey();

  @override
  void initState() {
    super.initState();

    currentDirectory = widget.currentDirectory;

    SharedPreferences.getInstance().then((prefs) => setState(() {
      preferences = prefs;
      _loadSettings(isGridViewSet: false);
    })).catchError((error, trace) => handleError(error, trace: trace));
  }

  void _loadSettings({ required bool isGridViewSet }) {
    showHiddenFiles = preferences.getBool(FileManagerSettings.showHiddenFiles.name) ?? false;

    if (!isGridViewSet) {
      gridView = preferences.getBool(FileManagerSettings.showGridView.name) ?? false;
    }

    if (currentDirectory != null) {
      final gridViewPaths = preferences.getStringList(FileManagerSettings.gridViewsPaths.name) ?? <String>[];
      if (!isGridViewSet) {
        gridView = gridViewPaths.contains(currentDirectory!.path);
      }
    }
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

  void _onEntryTap(BuildContext context, io.FileSystemEntity entry) {
    if (entry is io.Directory) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LibraryView(
            currentDirectory: entry,
          ),
        )
      );
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          OpenFile.open(entry.path).catchError((e) {
            _handleError(context, e);
            return OpenResult(type: ResultType.error, message: e.toString());
          });
          break;
        default:
          launchUrl(entry.uri).catchError((e) {
            _handleError(context, e);
            return true;
          });
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('assets/imgs/icon.png'),
              title: Text('File Manager${libraryTitle == null ? "" : ": ${libraryTitle!}"}'),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          leading: const DrawerWithClose(),
          leadingWidth: Navigator.of(context).canPop() ? 100.0 : 56.0,
          title: libraryTitle == null ? (currentDirectory == null ? null : Text(currentDirectory!.path)) : Text(libraryTitle!),
          actions: [
            IconButton(
              icon: gridView ? const Icon(Icons.list) : const Icon(
                  Icons.grid_4x4),
              onPressed: () =>
                  setState(() {
                    gridView = !gridView;

                    if (currentDirectory != null) {
                      final gridViewPaths = preferences.getStringList(FileManagerSettings.gridViewsPaths.name) ?? <String>[];
                      if (gridViewPaths.contains(currentDirectory!.path) && !gridView) {
                        gridViewPaths.remove(currentDirectory!.path);
                      } else if (!gridViewPaths.contains(currentDirectory!.path) && gridView) {
                        gridViewPaths.add(currentDirectory!.path);
                      }

                      preferences.setStringList(FileManagerSettings.gridViewsPaths.name, gridViewPaths).onError((error, stackTrace) {
                        _handleError(context, error!);
                        return true;
                      });
                    }
                  }),
            ),
          ],
        ),
        drawer: FileManagerDrawer(
          currentDirectory: currentDirectory,
        ),
        body: currentDirectory == null ? null : Center(
          child: RefreshIndicator(
            onRefresh: () async {
              await preferences.reload();
              setState(() {
                key = UniqueKey();
                _loadSettings(isGridViewSet: false);
              });
            },
            child: gridView ?
              FileBrowserGrid(
                key: key,
                showHidden: showHiddenFiles,
                directory: currentDirectory!,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                ),
                onTap: (entry) => _onEntryTap(context, entry),
              )
            : FileBrowserList(
              key: key,
              showHidden: showHiddenFiles,
              directory: currentDirectory!,
              onTap: (entry) => _onEntryTap(context, entry),
            ),
          ),
        ),
      );
}