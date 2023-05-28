import 'dart:convert';

import 'package:file_manager/logic.dart';
import 'package:file_manager/main.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pubspec/pubspec.dart';

class About extends StatelessWidget {
  const About({ super.key });
  
  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('assets/imgs/icon.png'),
              title: const Text('File Manager'),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          title: const Text('About'),
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(MediaQuery.of(context).size.height / 3.0),
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          'ExpidusOS File Manager',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        Text(
                          FileManagerApp.getPubSpec(context).description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        InkWell(
                          onTap: () => launchUrlString(FileManagerApp.getPubSpec(context).homepage!)
                              .catchError((error, trace) => handleError(error, trace: trace)),
                          child: Text(
                            FileManagerApp.getPubSpec(context).homepage!,
                            style: Theme.of(context).textTheme.bodyLarge!.copyWith(color: Theme.of(context).colorScheme.tertiary),
                          ),
                        ),
                        Text('${FileManagerApp.getPubSpec(context).name} v${FileManagerApp.getPubSpec(context).version}')
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    'Dependencies',
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                ),
                Column(
                  children: FileManagerApp.getPubSpec(context).allDependencies
                      .map((name, dep) {
                        Widget? subtitle = null;
                        if (dep is GitReference) {
                          subtitle = InkWell(
                            onTap: () =>
                                launchUrlString(dep.url)
                                    .catchError((error, trace) =>
                                    handleError(error, trace: trace)),
                            child: Text(
                              dep.url,
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(color: Theme
                                  .of(context)
                                  .colorScheme
                                  .tertiary),
                            ),
                          );
                        } else if (dep is HostedReference) {
                          subtitle = InkWell(
                            onTap: () =>
                                launchUrlString('https://pub.dev/packages/${name}')
                                    .catchError((error, trace) =>
                                    handleError(error, trace: trace)),
                            child: Text(
                              dep.versionConstraint.toString(),
                              style: Theme
                                  .of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(color: Theme
                                  .of(context)
                                  .colorScheme
                                  .tertiary),
                            ),
                          );
                        } else if (dep is SdkReference) {
                          subtitle = Text('SDK: ${dep.sdk!}');
                        }

                        return MapEntry(name, ListTile(
                          tileColor: Theme.of(context).cardTheme.color ?? Theme.of(context).cardColor,
                          shape: Theme.of(context).cardTheme.shape,
                          contentPadding: Theme.of(context).cardTheme.margin,
                          title: Text(name),
                          subtitle: subtitle,
                        ));
                      }).values.toList(),
                )
              ],
            ),
          ),
        ),
      );
}