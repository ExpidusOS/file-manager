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
import 'package:udisks/udisks.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_windows/path_provider_windows.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';
import 'dart:io' as io;

class LibraryEntry extends StatelessWidget {
  const LibraryEntry({
    super.key,
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

  @override
  Widget build(BuildContext context) =>
      ListTile(
        leading: Icon(iconData),
        title: Text(title),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LibraryView(
              currentDirectory: entry,
              parentContext: context,
            ),
            settings: RouteSettings(
              name: 'LibraryView',
              arguments: {
                'path': entry.path,
              },
            ),
          )
        ),
      );

  static LibraryEntry from(BuildContext context, {
    required StorageDirectory type,
    required io.Directory entry,
  }) {
    final i18n = AppLocalizations.of(context)!;
    switch (type) {
      case StorageDirectory.alarms:
        return LibraryEntry(title: i18n.libraryAlarms, entry: entry, iconData: Icons.alarm);
      case StorageDirectory.dcim:
        return LibraryEntry(title: i18n.libraryDCIM, entry: entry, iconData: Icons.photo_library);
      case StorageDirectory.documents:
        return LibraryEntry(title: i18n.libraryDocuments, entry: entry, iconData: Icons.folder);
      case StorageDirectory.downloads:
        return LibraryEntry(title: i18n.libraryDownloads, entry: entry, iconData: Icons.download);
      case StorageDirectory.movies:
        return LibraryEntry(title: i18n.libraryMovies, entry: entry, iconData: Icons.local_movies);
      case StorageDirectory.music:
        return LibraryEntry(title: i18n.libraryMusic, entry: entry, iconData: Icons.library_music);
      case StorageDirectory.pictures:
        return LibraryEntry(title: i18n.libraryPictures, entry: entry, iconData: Icons.photo_library);
      case StorageDirectory.podcasts:
        return LibraryEntry(title: i18n.libraryPodcasts, entry: entry, iconData: Icons.podcasts);
      case StorageDirectory.notifications:
        return LibraryEntry(title: i18n.libraryNotifications, entry: entry, iconData: Icons.notifications);
      case StorageDirectory.ringtones:
        return LibraryEntry(title: i18n.libraryRingtones, entry: entry, iconData: Icons.library_music);
      default:
        return LibraryEntry(title: type.name, entry: entry, iconData: Icons.folder);
    }
  }

  static LibraryEntry fromXdg(BuildContext context, {
    required String name,
    required io.Directory entry,
  }) {
    final i18n = AppLocalizations.of(context)!;
    switch (name) {
      case 'DESKTOP':
        return LibraryEntry(title: i18n.libraryDesktop, entry: entry, iconData: Icons.desktop_mac);
      case 'TEMPLATES':
        return LibraryEntry(title: i18n.libraryTemplates, entry: entry, iconData: Icons.folder);
      case 'PUBLICSHARE':
        return LibraryEntry(title: i18n.libraryPublic, entry: entry, iconData: Icons.public);
      case 'HOME':
        return LibraryEntry(title: i18n.libraryHome, entry: entry, iconData: Icons.home);
      case 'DOWNLOAD':
        return from(
          context,
          type: StorageDirectory.downloads,
          entry: entry,
        );
      case 'DOCUMENTS':
        return from(
          context,
          type: StorageDirectory.documents,
          entry: entry,
        );
      case 'MUSIC':
        return from(
          context,
          type: StorageDirectory.music,
          entry: entry,
        );
      case 'PICTURES':
        return from(
          context,
          type: StorageDirectory.pictures,
          entry: entry,
        );
      case 'VIDEOS':
        return from(
          context,
          type: StorageDirectory.movies,
          entry: entry,
        );
      default:
        return LibraryEntry(title: name, entry: entry, iconData: Icons.folder);
    }
  }

  static LibraryEntry? getDefaultEntry(BuildContext context) {
    final i18n = AppLocalizations.of(context)!;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return LibraryEntry(title: i18n.libraryStorage, entry: io.Directory('/storage/emulated/0'), iconData: Icons.storage);
      case TargetPlatform.linux:
        return LibraryEntry.fromXdg(context, name: 'HOME', entry: io.Directory(io.Platform.environment['HOME']!));
      case TargetPlatform.windows:
        return LibraryEntry.fromXdg(context, name: 'HOME', entry: io.Directory(io.Platform.environment['USERPROFILE']!));
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
        case PermissionStatus.provisional:
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

  static Future<List<LibraryEntry>> genList(BuildContext context) async {
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
          entries.add(LibraryEntry.from(context, type: type, entry: entry));
        }
        break;
      case TargetPlatform.linux:
        for (var name in getUserDirectoryNames()) {
          final entry = getUserDirectory(name);
          if (entry == null) continue;

          entries.add(LibraryEntry.fromXdg(context, name: name, entry: entry));
        }

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
      case TargetPlatform.windows:
        final pathProvider = PathProviderPlatform.instance as PathProviderWindows;

        final i18n = AppLocalizations.of(context)!;
        entries.addAll([
          LibraryEntry(
            title: i18n.libraryDesktop,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Desktop))!),
            iconData: Icons.desktop_windows
          ),
          LibraryEntry.from(
            context,
            type: StorageDirectory.documents,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Documents))!),
          ),
          LibraryEntry.from(
            context,
            type: StorageDirectory.movies,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Videos))!),
          ),
          LibraryEntry.from(
            context,
            type: StorageDirectory.music,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Music))!),
          ),
          LibraryEntry.from(
            context,
            type: StorageDirectory.downloads,
            entry: io.Directory((await pathProvider.getPath(FOLDERID_Downloads))!),
          ),
          LibraryEntry.fromXdg(
            context,
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
            elem.add(val);
          }
        }

        entries.addAll(drives.map((drive) =>
          LibraryEntry(
            title: drive,
            entry: io.Directory(drive),
            iconData: Icons.storage,
            group: 1,
          )
        ));
        break;
      default:
        for (var type in StorageDirectory.values) {
          final dirs = await getExternalStorageDirectories(type: type);
          if (dirs == null || dirs.isEmpty) continue;

          entries.add(LibraryEntry.from(context, type: type, entry: dirs[0]));
        }
        break;
    }

    final favoritePaths = prefs.getStringList(FileManagerSettings.favoritePaths.name) ?? <String>[];
    for (final favoritePath in favoritePaths) {
      entries.add(LibraryEntry(
        entry: io.Directory(favoritePath),
        title: favoritePath,
        iconData: Icons.star,
        group: 2,
      ));
    }

    final defaultEntry = getDefaultEntry(context);
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
        widgets.addAll(sort(entries));
        return MapEntry(groupId, widgets);
      }).values.flattened.toList();

  static Map<int, List<LibraryEntry>> mapGroups(List<LibraryEntry> entries) => entries.groupListsBy((entry) => entry.group);

  static LibraryEntry? find({
    required List<LibraryEntry> entries,
    required io.Directory directory,
  }) => entries.firstWhereOrNull((entry) => directory.path.startsWith(entry.entry.path));
}
