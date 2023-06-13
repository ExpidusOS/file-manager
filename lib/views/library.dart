import 'package:file_manager/constants.dart';
import 'package:file_manager/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:libtokyo_flutter/libtokyo.dart' hide Feedback;
import 'package:file_manager/logic.dart';
import 'package:file_manager/widgets.dart';
import 'package:file_manager/views.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file_plus/open_file_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  List<ClipboardEntry> clipboard = <ClipboardEntry>[];
  bool runningClipboard = false;
  bool isFavorite = false;

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

      final favoritePaths = preferences.getStringList(FileManagerSettings.favoritePaths.name) ?? <String>[];
      isFavorite = favoritePaths.contains(currentDirectory!.path);
    }
  }

  void _handleError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.fileOpenErrorMessage(e.toString())),
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
          settings: RouteSettings(
            name: 'LibraryView',
            arguments: {
              'path': entry.path,
            },
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
  
  void _onEntryLongPress(BuildContext context, io.FileSystemEntity entry) {
    final clipboard = Provider.of<Clipboard>(context, listen: false);
    if (clipboard.hasItemForEntry(entry)) {
      clipboard.removeItemForEntry(entry);

      setState(() {
        key = UniqueKey();
      });
    } else {
      final RenderBox tile = context.findRenderObject()! as RenderBox;
      final overlay = Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;

      showMenu<ClipboardAction>(
        context: context,
        items: [
          PopupMenuItem(
            value: ClipboardAction.copy,
            child: Text(AppLocalizations.of(context)!.libraryItemActionCopy),
          ),
          PopupMenuItem(
            value: ClipboardAction.move,
            child: Text(AppLocalizations.of(context)!.libraryItemActionMove),
          ),
          PopupMenuItem(
            value: ClipboardAction.link,
            child: Text(AppLocalizations.of(context)!.libraryItemActionLink),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: ClipboardAction.delete,
            child: Text(AppLocalizations.of(context)!.libraryItemActionDelete),
          )
        ],
        position: RelativeRect.fromRect(
          Rect.fromPoints(
            tile.localToGlobal(Offset.zero, ancestor: overlay),
            tile.localToGlobal(tile.size.bottomRight(Offset.zero), ancestor: overlay)
          ),
          Offset.zero & overlay.size,
        )
      ).then((action) {
        if (action != null) {
          clipboard.add(ClipboardEntry(action: action, entry: entry));

          setState(() {
            key = UniqueKey();
          });
        }
      });
    }
  }

  void _onDestinationSelected(int i) {
    if (i >= libraryEntries.length) {
      switch (i - libraryEntries.length) {
        case 0:
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SettingsView(),
              settings: const RouteSettings(name: 'Settings'),
            )
          );
          break;
        default:
          break;
      }
    } else {
      final entry = libraryEntries[i].entry;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LibraryView(
            currentDirectory: entry,
          ),
          settings: RouteSettings(
            name: 'LibraryView',
            arguments: {
              'path': entry.path,
            },
          ),
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var leadingWidth = 0.0;
    if (Breakpoints.smallMobile.isActive(context)) leadingWidth += 52;
    if (Navigator.of(context).canPop()) leadingWidth += 48;

    final destinations = <NavigationDestination>[
      ...LibraryEntry.sort(libraryEntries).map((entry) => NavigationDestination(
        icon: Icon(entry.iconData),
        label: entry.title,
      )),
      NavigationDestination(
        icon: const Icon(Icons.settings),
        label: AppLocalizations.of(context)!.viewSettings,
      ),
    ];
    return FutureBuilder(
        future: populateLibraryEntries(context),
        builder: (context, snapshot) =>
            Consumer<Clipboard>(
              builder: (context, clipboard, widget) =>
                  Scaffold(
                    windowBar: WindowBar.shouldShow(context) ? WindowBar(
                      leading: Image.asset('assets/imgs/icon.png'),
                      title: Text(
                          libraryTitle == null ? AppLocalizations.of(context)!
                              .applicationTitle
                              : AppLocalizations.of(context)!
                              .applicationTitleWithLibraryName(libraryTitle!)),
                    ) : null,
                    appBar: AppBar(
                      leading: DrawerWithClose(canOpenDrawer: Breakpoints.smallMobile.isActive(context)),
                      leadingWidth: leadingWidth,
                      title: libraryTitle == null ? (currentDirectory == null
                          ? null
                          : Text(currentDirectory!.path)) : Text(libraryTitle!),
                      actions: [
                        IconButton(
                          icon: gridView ? const Icon(Icons.list) : const Icon(
                              Icons.grid_4x4),
                          onPressed: () =>
                              setState(() {
                                gridView = !gridView;

                                if (currentDirectory != null) {
                                  final gridViewPaths = preferences
                                      .getStringList(
                                      FileManagerSettings.gridViewsPaths
                                          .name) ?? <String>[];
                                  if (gridViewPaths.contains(currentDirectory!
                                      .path) && !gridView) {
                                    gridViewPaths.remove(
                                        currentDirectory!.path);
                                  } else if (!gridViewPaths.contains(
                                      currentDirectory!.path) && gridView) {
                                    gridViewPaths.add(currentDirectory!.path);
                                  }

                                  preferences.setStringList(FileManagerSettings
                                      .gridViewsPaths.name, gridViewPaths)
                                      .onError((error, stackTrace) {
                                    _handleError(context, error!);
                                    return true;
                                  });
                                }
                              }),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            switch (value) {
                              case 'mkfile':
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      SingleTextInputFormDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .dialogCreateFileTitle),
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                              context)!
                                              .dialogCreateEntryFieldName,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .dialogCreateEntryEmptyName;
                                          }
                                          return null;
                                        },
                                        buildActions: (context, formKey,
                                            value) =>
                                        [
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .dialogCreateEntryActionCancel),
                                            onPressed: () =>
                                                Navigator.of(context).pop(
                                                    'Cancel'),
                                          ),
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .dialogCreateEntryActionCreate),
                                            onPressed: () {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                assert(value != null &&
                                                    value.isNotEmpty);
                                                io.File(path.join(
                                                    currentDirectory!.path,
                                                    value!)).create().then((
                                                    file) {
                                                  Navigator.of(context).pop(
                                                      'Create');
                                                  setState(() {
                                                    key = UniqueKey();
                                                    _loadSettings(
                                                        isGridViewSet: false);
                                                  });
                                                }).catchError((error, trace) {
                                                  handleError(
                                                      error, trace: trace);
                                                  _handleError(context, error);
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                );
                                break;
                              case 'mkdir':
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>
                                      SingleTextInputFormDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .dialogCreateDirectoryTitle),
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(
                                              context)!
                                              .dialogCreateEntryFieldName,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return AppLocalizations.of(context)!
                                                .dialogCreateEntryEmptyName;
                                          }
                                          return null;
                                        },
                                        buildActions: (context, formKey,
                                            value) =>
                                        [
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .dialogCreateEntryActionCancel),
                                            onPressed: () =>
                                                Navigator.of(context).pop(
                                                    'Cancel'),
                                          ),
                                          TextButton(
                                            child: Text(
                                                AppLocalizations.of(context)!
                                                    .dialogCreateEntryActionCreate),
                                            onPressed: () {
                                              if (formKey.currentState!
                                                  .validate()) {
                                                assert(value != null &&
                                                    value.isNotEmpty);

                                                io.Directory(path.join(
                                                    currentDirectory!.path,
                                                    value!)).create().then((
                                                    dir) {
                                                  Navigator.of(context).pop(
                                                      'Create');
                                                  setState(() {
                                                    currentDirectory = dir;
                                                    key = UniqueKey();
                                                    _loadSettings(
                                                        isGridViewSet: false);
                                                  });
                                                }).catchError((error, trace) {
                                                  handleError(
                                                      error, trace: trace);
                                                  _handleError(context, error);
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                );
                                break;
                              case 'favorite':
                                setState(() {
                                  isFavorite = !isFavorite;

                                  if (currentDirectory != null) {
                                    final favoritePaths = preferences
                                        .getStringList(
                                        FileManagerSettings.favoritePaths
                                            .name) ?? <String>[];
                                    if (favoritePaths.contains(
                                        currentDirectory!.path) &&
                                        !isFavorite) {
                                      favoritePaths.remove(
                                          currentDirectory!.path);
                                    } else if (!favoritePaths.contains(
                                        currentDirectory!.path) && isFavorite) {
                                      favoritePaths.add(currentDirectory!.path);
                                    }

                                    preferences.setStringList(
                                        FileManagerSettings.favoritePaths.name,
                                        favoritePaths).onError((error,
                                        stackTrace) {
                                      _handleError(context, error!);
                                      return true;
                                    });
                                  }
                                });
                                break;
                              case 'feedback':
                                Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Feedback(
                                            id: gridView
                                                ? FileManagerFeedbackID
                                                .viewLibraryGrid
                                                : FileManagerFeedbackID
                                                .viewLibraryList,
                                          ),
                                      settings: const RouteSettings(
                                          name: 'Feedback'),
                                    )
                                );
                                break;
                            }
                          },
                          itemBuilder: (context) =>
                          [
                            PopupMenuItem(
                              value: 'mkfile',
                              child: Text(AppLocalizations.of(context)!
                                  .viewLibraryActionCreateFile),
                            ),
                            PopupMenuItem(
                              value: 'mkdir',
                              child: Text(AppLocalizations.of(context)!
                                  .viewLibraryActionCreateDirectory),
                            ),
                            (isFavorite ? PopupMenuItem(
                              value: 'favorite',
                              child: Text(AppLocalizations.of(context)!
                                  .favoriteRemove),
                            ) : PopupMenuItem(
                              value: 'favorite',
                              child: Text(AppLocalizations.of(context)!
                                  .favoriteAdd),
                            )),
                            ...(FileManagerApp.isSentryOnContext(context) ? <
                                PopupMenuEntry<String>>[
                              const PopupMenuDivider(),
                              PopupMenuItem(
                                value: 'feedback',
                                child: Text(AppLocalizations.of(context)!
                                    .feedbackSend),
                              ),
                            ] : <PopupMenuEntry<String>>[]),
                          ],
                        ),
                      ],
                    ),
                    drawer: Breakpoints.smallMobile.isActive(context)
                        ? FileManagerDrawer(
                      currentDirectory: currentDirectory,
                    )
                        : null,
                    body: currentDirectory == null || destinations.length < 2 ? null : AdaptiveLayout(
                      internalAnimations: false,
                      primaryNavigation: SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          Breakpoints.medium: SlotLayout.from(
                            key: const Key('primaryNavigation'),
                            builder: (_) => NavigationRailTheme(
                              data: Theme.of(context).navigationRailTheme.copyWith(
                                elevation: AppBarTheme.of(context).elevation ?? Theme.of(context).appBarTheme.elevation ?? 4,
                              ),
                              child: AdaptiveScaffold.standardNavigationRail(
                                destinations: destinations.map((_) => AdaptiveScaffold.toRailDestination(_)).toList(),
                                backgroundColor: Theme.of(context).colorScheme.background,
                                selectedIndex: currentLibrary != null ? libraryEntries.indexOf(currentLibrary!) : null,
                                selectedLabelTextStyle: Theme.of(context).textTheme.bodyLarge,
                                unSelectedLabelTextStyle: Theme.of(context).textTheme.bodyLarge,
                                selectedIconTheme: IconTheme.of(context).copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                unselectedIconTheme: IconTheme.of(context).copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onDestinationSelected: _onDestinationSelected,
                              )
                            ),
                          ),
                          Breakpoints.large: SlotLayout.from(
                            key: const Key('primaryNavigation'),
                            builder: (_) => NavigationRailTheme(
                              data: Theme.of(context).navigationRailTheme.copyWith(
                                elevation: AppBarTheme.of(context).elevation ?? Theme.of(context).appBarTheme.elevation ?? 4,
                              ),
                              child: AdaptiveScaffold.standardNavigationRail(
                                destinations: destinations.map((_) => AdaptiveScaffold.toRailDestination(_)).toList(),
                                backgroundColor: Theme.of(context).colorScheme.background,
                                selectedIndex: currentLibrary != null ? libraryEntries.indexOf(currentLibrary!) : null,
                                selectedLabelTextStyle: Theme.of(context).textTheme.bodyLarge,
                                unSelectedLabelTextStyle: Theme.of(context).textTheme.bodyLarge,
                                selectedIconTheme: IconTheme.of(context).copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                unselectedIconTheme: IconTheme.of(context).copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onDestinationSelected: _onDestinationSelected,
                                extended: true,
                              )
                            ),
                          ),
                        },
                      ),
                      body: SlotLayout(
                        config: <Breakpoint, SlotLayoutConfig>{
                          Breakpoints.standard: SlotLayout.from(
                            key: const Key('body'),
                            builder: (_) => Center(
                              child: RefreshIndicator(
                                  onRefresh: () async {
                                    await preferences.reload();
                                    setState(() {
                                      key = UniqueKey();
                                      _loadSettings(isGridViewSet: false);
                                    });
                                  },
                                  child: ListTileTheme(
                                      selectedTileColor: Theme
                                          .of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                      tileColor: Colors.transparent,
                                      child: gridView ? FileBrowserGrid(
                                        key: key,
                                        showHidden: showHiddenFiles,
                                        directory: currentDirectory!,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 5,
                                        ),
                                        createEntryWidget: (entry) =>
                                            FileBrowserGridEntry(
                                              entry: entry,
                                              onTap: () => _onEntryTap(context, entry),
                                              onLongPress: () =>
                                                  _onEntryLongPress(context, entry),
                                              selected: clipboard.hasItemForEntry(
                                                  entry),
                                            ),
                                      ) : FileBrowserList(
                                        key: key,
                                        showHidden: showHiddenFiles,
                                        directory: currentDirectory!,
                                        createEntryWidget: (entry) =>
                                            FileBrowserListEntry(
                                              entry: entry,
                                              onTap: () => _onEntryTap(context, entry),
                                              onLongPress: () =>
                                                  _onEntryLongPress(context, entry),
                                              selected: clipboard.hasItemForEntry(
                                                  entry),
                                            ),
                                      )
                                  )
                              ),
                            ),
                          )
                        },
                      ),
                    ),
                    bottomNavigationBar: clipboard.items.isNotEmpty ||
                        runningClipboard ?
                    BottomAppBar(
                      shape: AutomaticNotchedShape(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          )
                      ),
                      height: kToolbarHeight / 1.5,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4.0, horizontal: 16.0),
                        child: Builder(
                            builder: (context) {
                              final i18n = AppLocalizations.of(context)!;

                              if (runningClipboard) {
                                return StreamBuilder<ClipboardProcState>(
                                  stream: clipboard.run(currentDirectory!),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasError) {
                                      runningClipboard = false;
                                      key = UniqueKey();
                                      clipboard.clear(notify: false);
                                      return Text(i18n.genericErrorMessage(
                                          snapshot.error!.toString()));
                                    }

                                    switch (snapshot.connectionState) {
                                      case ConnectionState.waiting:
                                      case ConnectionState.none:
                                      case ConnectionState.active:
                                        return const LinearProgressIndicator();
                                      case ConnectionState.done:
                                        runningClipboard = false;
                                        key = UniqueKey();
                                        clipboard.clear(notify: false);
                                        return const LinearProgressIndicator(
                                          value: 1.0,
                                        );
                                    }
                                  },
                                );
                              }

                              var labels = <Widget>[];

                              final copyCount = clipboard.countForAction(
                                  ClipboardAction.copy);
                              final moveCount = clipboard.countForAction(
                                  ClipboardAction.move);
                              final linkCount = clipboard.countForAction(
                                  ClipboardAction.link);
                              final deleteCount = clipboard.countForAction(
                                  ClipboardAction.delete);

                              if (copyCount > 0) {
                                labels.add(
                                  Text(i18n.clipboardCopyLabel(copyCount)));
                              }
                              if (moveCount > 0) {
                                labels.add(
                                  Text(i18n.clipboardMoveLabel(moveCount)));
                              }
                              if (linkCount > 0) {
                                labels.add(
                                  Text(i18n.clipboardLinkLabel(linkCount)));
                              }
                              if (deleteCount > 0) {
                                labels.add(
                                  Text(i18n.clipboardDeleteLabel(deleteCount)));
                              }

                              return Column(
                                mainAxisAlignment: MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Flexible(
                                    child: NavigationToolbar(
                                      middle: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        children: labels,
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment
                                            .center,
                                        children: [
                                          OutlinedButton(
                                            child: Text(i18n.clipboardExecute),
                                            onPressed: () =>
                                                setState(() {
                                                  runningClipboard = true;
                                                }),
                                          ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(Icons.clear),
                                            onPressed: () => clipboard.clear(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                        ),
                      ),
                    )
                        : null,
                  ),
            )
    );
  }
}