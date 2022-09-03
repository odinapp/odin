import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';

part 'widgets/main_container.dart';
// part 'widgets/bg_illustration.dart';
// part 'widgets/primary_button.dart';
// part 'widgets/header_title.dart';
// part 'widgets/or_divider.dart';
// part 'widgets/secondary_button.dart';

class UploadPage extends StatelessWidget {
  const UploadPage({
    Key? key,
    required this.uploadFiles,
  }) : super(key: key);

  final List<File> uploadFiles;

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
      child: MainContainer(color: color),
    );
  }
}
