import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' as io;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({ super.key });

  @override
  Widget build(BuildContext context) {
    return TokyoApp(
      title: 'Flutter Demo',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({ super.key, this.directory, this.gridView });

  final io.Directory? directory;
  final bool? gridView;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  io.Directory? currentDirectory;
  bool gridView = false;

  @override
  void initState() {
    super.initState();

    gridView = widget.gridView ?? false;
    currentDirectory = widget.directory;
    if (currentDirectory == null) {
      if (io.Platform.isAndroid) {
        currentDirectory = io.Directory('/storage/emulated/0');
      } else {
        currentDirectory = io.Directory.current;
      }
    }

    for (var type in StorageDirectory.values) {
      getExternalStorageDirectories(type: type).then((dirs) => print("${type} = ${dirs}")).catchError(print);
    }
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
          builder: (context) => HomePage(
            directory: entry as io.Directory,
            gridView: gridView,
          )
        )
      );
    } else {
      launchUrl(entry.uri).catchError((e) => _handleError(context, e));
    }
  }

  Widget _buildBody(BuildContext context) =>
    gridView ?
      FileBrowserGrid(
        directory: currentDirectory!,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
        ),
        onTap: (entry) => _onEntryTap(context, entry),
      )
    : FileBrowserList(
        directory: currentDirectory!,
        onTap: (entry) => _onEntryTap(context, entry),
      );

  @override
  Widget build(BuildContext context) =>
    Scaffold(
      windowBar: WindowBar.shouldShow(context) && !kIsWeb ? WindowBar(
        leading: Image.asset('imgs/icon.png'),
        title: const Text('File Manager'),
      ) : null,
      appBar: AppBar(
        title: currentDirectory != null ? Text(currentDirectory!.path) : null,
        actions: [
          IconButton(
            icon: gridView ? const Icon(Icons.list) : const Icon(Icons.grid_4x4),
            onPressed: () => setState(() {
              gridView = !gridView;
            }),
          ),
        ],
      ),
      body: Center(
        child: currentDirectory != null ? _buildBody(context) : Text('Directory path is not initialized'),
      ),
    );
}
