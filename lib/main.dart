import 'package:collection/collection.dart';
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
  Widget build(BuildContext context) =>
      TokyoApp(
      title: 'Flutter Demo',
      home: const HomePage(),
    );
}

class HomePage extends StatefulWidget {
  const HomePage({ super.key, this.directory, this.gridView });

  final io.Directory? directory;
  final bool? gridView;

  @override
  State<HomePage> createState() => _HomePageState();
}

class LibraryEntry {
  LibraryEntry({ required this.title, required this.entry, required this.iconData });

  final String title;
  final io.Directory entry;
  final IconData iconData;

  Widget build(BuildContext context) =>
    ListTile(
      leading: Icon(iconData),
      title: Text(title),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => HomePage(
            directory: entry,
          ),
        )
      ),
    );

  static LibraryEntry from(StorageDirectory type, io.Directory entry) {
    switch (type) {
      case StorageDirectory.alarms:
        return LibraryEntry(title: 'Alarms', entry: entry, iconData: Icons.alarm);
      case StorageDirectory.dcim:
        return LibraryEntry(title: 'DCIM', entry: entry, iconData: Icons.photo_library);
      case StorageDirectory.documents:
        return LibraryEntry(title: 'Documents', entry: entry, iconData: Icons.folder);
      case StorageDirectory.downloads:
        return LibraryEntry(title: 'Downloads', entry: entry, iconData: Icons.download);
      case StorageDirectory.movies:
        return LibraryEntry(title: 'Movies', entry: entry, iconData: Icons.local_movies);
      case StorageDirectory.music:
        return LibraryEntry(title: 'Music', entry: entry, iconData: Icons.library_music);
      case StorageDirectory.pictures:
        return LibraryEntry(title: 'Pictures', entry: entry, iconData: Icons.photo_library);
      case StorageDirectory.podcasts:
        return LibraryEntry(title: 'Podcasts', entry: entry, iconData: Icons.podcasts);
      case StorageDirectory.notifications:
        return LibraryEntry(title: 'Notifications', entry: entry, iconData: Icons.notifications);
      case StorageDirectory.ringtones:
        return LibraryEntry(title: 'Ringtones', entry: entry, iconData: Icons.library_music);
      default:
        return LibraryEntry(title: type.name, entry: entry, iconData: Icons.folder);
    }
  }
}

class _HomePageState extends State<HomePage> {
  io.Directory? currentDirectory;
  Map<StorageDirectory, LibraryEntry> directories = {};
  bool gridView = false;

  MapEntry<StorageDirectory, LibraryEntry>? get currentEntry =>
      currentDirectory == null ? null : (directories.entries.firstWhereOrNull((element) => currentDirectory!.path.startsWith(element.value.entry.path)));

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
      getExternalStorageDirectories(type: type).then((dirs) {
        if (dirs != null && dirs.isNotEmpty) {
          setState(() {
            directories[type] = LibraryEntry.from(type, dirs[0]);
          });
        }
      }).catchError(print);
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
  Widget build(BuildContext context) {
    return Scaffold(
      windowBar: WindowBar.shouldShow(context) && !kIsWeb ? WindowBar(
        leading: Image.asset('imgs/icon.png'),
        title: const Text('File Manager'),
      ) : null,
      appBar: AppBar(
        title: currentDirectory == null ? null : Text(currentEntry == null ? currentDirectory!.path : currentDirectory!.path.replaceFirst(currentEntry!.value.entry.path, currentEntry!.value.title)),
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme
                    .of(context)
                    .colorScheme
                    .onSurface,
              ),
              child: currentEntry == null ? const Text('TODO: total free space') : Row(
                children: [
                  Icon(
                      currentEntry!.value.iconData,
                    size: Theme.of(context).textTheme.displaySmall!.fontSize,
                  ),
                  Text(
                    currentEntry!.value.title,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            )
          ]..addAll(directories.values.sorted((a, b) => a.title.compareTo(b.title)).map((e) => e.build(context)).toList()),
        ),
      ),
      body: Center(
        child: currentDirectory != null ? _buildBody(context) : Text(
            'Directory path is not initialized'),
      ),
    );
  }
}
