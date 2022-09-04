import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/utilities/byte_formatter.dart';
import 'package:provider/provider.dart';

part 'widgets/main_container.dart';
part 'widgets/back_button.dart';
part 'widgets/cross_button.dart';
part 'widgets/header_text.dart';
part 'widgets/info_text.dart';
part 'widgets/progress_bar.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({
    Key? key,
    required this.uploadFiles,
  }) : super(key: key);

  final List<File> uploadFiles;

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  @override
  void initState() {
    super.initState();
    _uploadFiles();
  }

  Future<void> _uploadFiles() async {
    final dioNotifier = locator<DioNotifier>();
    final uploadFiles = widget.uploadFiles;

    await dioNotifier.uploadFilesAnonymous(
      uploadFiles,
      (count, total) {},
    );
  }

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
