import 'package:libtokyo_flutter/libtokyo.dart';

class DrawerWithClose extends StatelessWidget {
  const DrawerWithClose({ super.key, this.onBack, this.canGoBack });

  final bool? canGoBack;
  final void Function()? onBack;

  @override
  Widget build(BuildContext context) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: (canGoBack ?? Navigator.of(context).canPop() ? <Widget>[
          IconButton(
            onPressed: () => onBack == null ? Navigator.of(context).pop() : onBack!(),
            icon: const Icon(Icons.arrow_back_ios),
          )
        ] : <Widget>[])..add(
          const DrawerButton(),
        ),
      );
}