import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/images.dart';
import 'package:odin/network/repository.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/constants/size.dart';
import 'package:odin/utilities/byte_formatter.dart';
import 'package:odin/utilities/networking.dart';
import 'package:provider/provider.dart';

part 'widgets/main_container.dart';
part 'widgets/back_button.dart';
part 'widgets/cross_button.dart';
part 'widgets/header_text.dart';
part 'widgets/info_text.dart';
part 'widgets/progress_bar.dart';
part 'widgets/success_body.dart';
part 'widgets/failure_body.dart';

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
        child: () {
          switch (Provider.of<DioNotifier>(context).apiStatus) {
            case ApiStatus.init:
            case ApiStatus.loading:
              return const _Body();
            case ApiStatus.failed:
              return const _FailedBody();
            case ApiStatus.success:
              return const _SuccessBody();
            default:
          }
        }(),
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

class _FailedBody extends StatelessWidget {
  const _FailedBody({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final UploadFilesFailure? uploadFilesFailure = Provider.of<DioNotifier>(context).uploadFilesFailure;

    return Center(
      child: FailedBody(color: color, uploadFilesFailure: uploadFilesFailure!),
    );
  }
}

class _SuccessBody extends StatelessWidget {
  const _SuccessBody({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final OColor color = OColor.withContext(context);
    final UploadFilesSuccess? uploadFilesSuccess = Provider.of<DioNotifier>(context).uploadFilesSuccess;

    return Center(
      child: SuccessBody(color: color, uploadFilesSuccess: uploadFilesSuccess!),
    );
  }
}
