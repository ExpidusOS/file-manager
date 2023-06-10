import 'package:flutter/services.dart';
import 'package:libtokyo_flutter/libtokyo.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' hide Text;
import 'package:url_launcher/url_launcher_string.dart';

class _MarkdownConstantPadding extends MarkdownPaddingBuilder {
  _MarkdownConstantPadding({ required this.padding }) : super();

  final EdgeInsets padding;

  @override
  EdgeInsets getPadding() => padding;
}

class Privacy extends StatelessWidget {
  const Privacy({ super.key });

  void _handleError(BuildContext context, Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.genericErrorMessage(e.toString())),
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        windowBar: WindowBar.shouldShow(context) ? WindowBar(
          leading: Image.asset('assets/imgs/icon.png'),
          title: Text(AppLocalizations.of(context)!.applicationTitle),
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
                  paddingBuilders: {
                    "h1": _MarkdownConstantPadding(padding: const EdgeInsets.all(8.0)),
                    "h2": _MarkdownConstantPadding(padding: const EdgeInsets.all(8.0)),
                    "p": _MarkdownConstantPadding(padding: const EdgeInsets.all(8.0)),
                  },
                  onTapLink: (text, href, title) {
                    if (href != null) {
                      launchUrlString(href!).catchError((error) => _handleError(context, error));
                    }
                  },
                );
              }
              return const CircularProgressIndicator();
            },
          ),
        ),
      );
}