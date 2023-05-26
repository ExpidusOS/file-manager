import 'dart:ffi';
import 'package:collection/collection.dart';
import 'package:file_manager/constants.dart';
import 'package:file_manager/views.dart';
import 'package:flutter/foundation.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xdg_directories/xdg_directories.dart';
import 'package:universal_disk_space/universal_disk_space.dart';
import 'package:udisks/udisks.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:io' as io;

class LibraryEntry {
  LibraryEntry({
    this.group = 0,
    required this.title,
    required this.entry,
    required this.iconData,
  });

  final int group;
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

  static Future<bool> _checkPermission(Permission perm) async {
    var status = await perm.status;
    if (status.isPermanentlyDenied) {
      return await openAppSettings();
    }

    if (!status.isGranted) {
      switch (await perm.request()) {
        case PermissionStatus.granted:
        case PermissionStatus.limited:
          return true;
        case PermissionStatus.denied:
        case PermissionStatus.restricted:
          return false;
        case PermissionStatus.permanentlyDenied:
          return await openAppSettings();
      }
    }

    return status.isGranted;
  }

  static String _transformPathAndroid(StorageDirectory type, String p) {
    switch (type) {
      case StorageDirectory.dcim:
        return path.join('/storage/emulated/0', 'DCIM');
      case StorageDirectory.downloads:
        return path.join('/storage/emulated/0', 'Download');
      default:
        return path.join('/storage/emulated/0', '${path.basename(p)[0].toUpperCase()}${path.basename(p).substring(1)}');
    }
  }

  static Future<List<LibraryEntry>> genList() async {
    var entries = <LibraryEntry>[];
    final prefs = await SharedPreferences.getInstance();
    final showHiddenLibraries = prefs.getBool(FileManagerSettings.showHiddenLibraries.name) ?? false;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.windows:
        while (!await _checkPermission(Permission.manageExternalStorage));
        break;
      default:
        break;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        for (var type in StorageDirectory.values) {
          final dirs = await getExternalStorageDirectories(type: type);
          if (dirs == null || dirs.isEmpty) continue;

          final entry = io.Directory(_transformPathAndroid(type, dirs[0].path));
          entries.add(LibraryEntry.from(type: type, entry: entry));
        }
        break;
      case TargetPlatform.linux:
        for (var name in getUserDirectoryNames()) {
          final entry = getUserDirectory(name);
          if (entry == null) continue;

          entries.add(LibraryEntry.fromXdg(name: name, entry: entry));
        }
        break;
      case TargetPlatform.windows:
        final pathProvider = PathProviderPlatform.instance as PathProviderWindows;

        entries.addAll([
          LibraryEntry(
            title: 'Desktop',
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Desktop))!),
            iconData: Icons.desktop_windows
          ),
          LibraryEntry.from(
            type: StorageDirectory.documents,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Documents))!),
          ),
          LibraryEntry.from(
            type: StorageDirectory.movies,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Videos))!),
          ),
          LibraryEntry.from(
            type: StorageDirectory.music,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Music))!),
          ),
          LibraryEntry.from(
            type: StorageDirectory.downloads,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Downloads))!),
          ),
          LibraryEntry.fromXdg(
            name: 'HOME',
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Profile))!),
          ),
        ]);

        var buff = String.fromCharCodes(List.filled(1024, 0)).toNativeUtf16();
        GetLogicalDriveStrings(1024, buff);
        final arr = buff.cast<Uint16>().asTypedList(1024);

        var elem = <int>[];
        var drives = <String>[];
        for (var i = 0; i < arr.length; i++) {
          final val = arr[i];
          if (val == 0) {
            drives.add(String.fromCharCodes(elem));
            elem = <int>[];
          } else {
            elem.add(i);
          }
        }

        entries.addAll(drives.map((drive) =>
          LibraryEntry(title: drive, entry: io.Directory(drive), iconData: Icons.storage)
        ));
        break;
      default:
        for (var type in StorageDirectory.values) {
          final dirs = await getExternalStorageDirectories(type: type);
          if (dirs == null || dirs.isEmpty) continue;

          entries.add(LibraryEntry.from(type: type, entry: dirs[0]));
        }
        break;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
        var client = UDisksClient();
        await client.connect();

        for (var drive in client.blockDevices) {
          final fstab = drive.configuration.firstWhereOrNull((element) => element.type == 'fstab');
          if (fstab == null) continue;
          if (!fstab.details.containsKey('dir')) continue;
          if (drive.hintIgnore && !showHiddenLibraries) continue;

          final entry = io.Directory(String.fromCharCodes(fstab.details['dir']!.asByteArray().where((i) => i > 0)));

          entries.add(LibraryEntry(
            title: drive.hintName.isEmpty ? (drive.idLabel.isEmpty ? entry.path : drive.idLabel) : drive.hintName,
            entry: entry,
            iconData: Icons.storage,
            group: 1,
          ));
        }
        await client.close();
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        var diskSpace = DiskSpace();
        diskSpace.scan();
        print(diskSpace.disks);
        break;
      default:
        break;
    }

    if (defaultEntry != null) entries.add(defaultEntry!);
    return entries;
  }
  
  static List<LibraryEntry> sort(List<LibraryEntry> entries) =>
    entries..sort((a, b) => a.title.compareTo(b.title));

  static List<Widget> buildWidgets(List<LibraryEntry> entries, BuildContext context) =>
      mapGroups(entries).map((groupId, entries) {
        final widgets = entries.isNotEmpty && groupId > 0 ? <Widget>[
          const Divider(),
        ] : <Widget>[];
        widgets.addAll(sort(entries).map((e) => e.build(context)));
        return MapEntry(groupId, widgets);
      }).values.flattened.toList();

  static Map<int, List<LibraryEntry>> mapGroups(List<LibraryEntry> entries) => entries.groupListsBy((entry) => entry.group);

  static LibraryEntry? find({
    required List<LibraryEntry> entries,
    required io.Directory directory,
  }) => entries.firstWhereOrNull((entry) => directory.path.startsWith(entry.entry.path));
}