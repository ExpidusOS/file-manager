import 'package:libtokyo_flutter/libtokyo.dart';

class DrawerWithClose extends StatelessWidget {
  const DrawerWithClose({ super.key, this.onBack, this.canOpenDrawer = true, this.canGoBack });

  final bool? canGoBack;
  final bool canOpenDrawer;
  final void Function()? onBack;

  @override
  Widget build(BuildContext context) =>
      Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...(canGoBack ?? Navigator.of(context).canPop() ? [
            IconButton(
              onPressed: () => onBack == null ? Navigator.of(context).pop() : onBack!(),
              icon: const Icon(Icons.arrow_back_ios),
            )
          ] : []),
          ...(canOpenDrawer ? [
            const DrawerButton(),
          ] : []),
        ],
      );
}