import 'package:libtokyo_flutter/libtokyo.dart';

class DrawerWithClose extends StatelessWidget {
  const DrawerWithClose({ super.key });

  @override
  Widget build(BuildContext context) =>
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: (Navigator.of(context).canPop() ? <Widget>[
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios),
          )
        ] : <Widget>[])..add(
          const DrawerButton(),
        ),
      );
}