import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' hide Text;

class Privacy extends StatelessWidget {
  const Privacy({ super.key });

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight / 2),
          child: MoveWindow(
            child: WindowBar(
              leading: Image.asset('assets/imgs/icon.png'),
              title: Text(AppLocalizations.of(context)!.applicationTitle),
              onMinimize: () => appWindow.minimize(),
              onMaximize: () => appWindow.maximize(),
              onClose: () => appWindow.close(),
            ),
          ),
        ) : null,
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.viewPrivacy),
        ),
        body: SingleChildScrollView(
          child: FutureBuilder(
            future: rootBundle.loadString('PRIVACY.md'),
            builder: (context, snapshot) {
              final i18n = AppLocalizations.of(context)!;
              
              if (snapshot.hasError) {
                return Text(i18n.genericErrorMessage(snapshot.error!.toString()));
              }
              
              if (snapshot.hasData) {
                return MarkdownBody(
                  data: snapshot.data!,
                  extensionSet: ExtensionSet.gitHubFlavored,
                  styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      );
}