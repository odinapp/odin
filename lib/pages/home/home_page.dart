import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';

part 'widgets/main_container.dart';
part 'widgets/bg_illustration.dart';
part 'widgets/primary_button.dart';
part 'widgets/header_title.dart';
part 'widgets/divider.dart';
part 'widgets/secondary_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    oApp.currentContext = context;
    final OColor color = OColor.withContext(context);

    return Scaffold(
      backgroundColor: color.background,
      body:
          // Gradient background
          Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.background, color.backgroundContainer],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: const _Body(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          MainContainer(color: color),
          54.toVerticalSizedBox,
          const OrDivider(),
          SecondaryButton(color: color),
        ],
      ),
    );
  }
}
