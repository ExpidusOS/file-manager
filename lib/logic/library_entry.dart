import 'package:collection/collection.dart';
import 'package:file_manager/views.dart';
import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'dart:io' as io;

class LibraryEntry {
  LibraryEntry({
    required this.title,
    required this.entry,
    required this.iconData,
  });

  final String title;
  final io.Directory entry;
  final IconData iconData;

  String titleFor(io.Directory dir) => dir.path.replaceFirst(entry.path, title);

  Widget build(BuildContext context) =>
      ListTile(
        leading: Icon(iconData),
        title: Text(title),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LibraryView(
              currentDirectory: entry,
            ),
          )
        ),
      );

  static LibraryEntry from({
    required StorageDirectory type,
    required io.Directory entry,
  }) {
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

  static LibraryEntry fromXdg({
    required String name,
    required io.Directory entry,
  }) {
    switch (name) {
      case 'DESKTOP':
        return LibraryEntry(title: 'Desktop', entry: entry, iconData: Icons.desktop_mac);
      case 'TEMPLATES':
        return LibraryEntry(title: 'Templates', entry: entry, iconData: Icons.folder);
      case 'PUBLICSHARE':
        return LibraryEntry(title: 'Public', entry: entry, iconData: Icons.public);
      case 'DOWNLOAD':
        return from(
          type: StorageDirectory.downloads,
          entry: entry,
        );
      case 'DOCUMENTS':
        return from(
          type: StorageDirectory.documents,
          entry: entry,
        );
      case 'MUSIC':
        return from(
          type: StorageDirectory.music,
          entry: entry,
        );
      case 'PICTURES':
        return from(
          type: StorageDirectory.pictures,
          entry: entry,
        );
      case 'VIDEOS':
        return from(
          type: StorageDirectory.movies,
          entry: entry,
        );
      default:
        return LibraryEntry(title: name, entry: entry, iconData: Icons.folder);
    }
  }

  static LibraryEntry? get defaultEntry {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return LibraryEntry(title: 'Storage', entry: io.Directory('/storage/emulated/0'), iconData: Icons.storage);
      case TargetPlatform.linux:
        return LibraryEntry(title: 'Home', entry: io.Directory(io.Platform.environment['HOME'] ?? io.Directory.current.path), iconData: Icons.home);
      default:
        return null;
    }
  }

  static Future<List<LibraryEntry>> genList() async {
    var entries = <LibraryEntry>[];

    if (defaultTargetPlatform == TargetPlatform.linux) {
      for (var name in getUserDirectoryNames()) {
        final entry = getUserDirectory(name);
        if (entry == null) continue;

        entries.add(LibraryEntry.fromXdg(name: name, entry: entry));
      }
    } else {
      for (var type in StorageDirectory.values) {
        final dirs = await getExternalStorageDirectories(type: type);
        if (dirs == null || dirs.isEmpty) continue;

        entries.add(LibraryEntry.from(type: type, entry: dirs[0]));
      }
    }

    if (defaultEntry != null) entries.add(defaultEntry!);
    return entries;
  }

  static LibraryEntry? find({
    required List<LibraryEntry> entries,
    required io.Directory directory,
  }) => entries.firstWhereOrNull((entry) => directory.path.startsWith(entry.entry.path));
}