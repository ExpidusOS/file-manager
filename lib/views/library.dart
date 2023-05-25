import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:file_manager/logic.dart';
import 'package:file_manager/widgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool gridView = false;
  bool showHidden = false;

  @override
  void initState() {
    super.initState();

    currentDirectory = widget.currentDirectory;

    SharedPreferences.getInstance().then((prefs) => setState(() {
      showHidden = prefs.getBool("hidden") ?? false;
    })).catchError((error) => FlutterError.reportError(FlutterErrorDetails(exception: error)));
  }

  void _handleError(BuildContext context, Object e) {
    if (e is Error) {
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
      launchUrl(entry.uri).catchError((e) {
        _handleError(context, e);
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('imgs/icon.png'),
              title: Text('File Manager${libraryTitle == null ? "" : ": ${libraryTitle!}"}'),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          title: libraryTitle == null ? (currentDirectory == null ? null : Text(currentDirectory!.path)) : Text(libraryTitle!),
          actions: [
            IconButton(
              icon: gridView ? const Icon(Icons.list) : const Icon(
                  Icons.grid_4x4),
              onPressed: () =>
                  setState(() {
                    gridView = !gridView;
                  }),
            ),
          ],
        ),
        drawer: FileManagerDrawer(
          currentDirectory: currentDirectory,
        ),
        body: currentDirectory == null ? null : Center(
          child: gridView ?
            FileBrowserGrid(
              showHidden: showHidden,
              directory: currentDirectory!,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),
              onTap: (entry) => _onEntryTap(context, entry),
            )
          : FileBrowserList(
            showHidden: showHidden,
            directory: currentDirectory!,
            onTap: (entry) => _onEntryTap(context, entry),
          ),
        ),
      );
}