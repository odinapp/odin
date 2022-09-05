import 'package:flutter/gestures.dart';
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
import 'package:odin/utilities/debounce.dart';
import 'package:odin/utilities/networking.dart';
import 'package:provider/provider.dart';

part 'widgets/main_container.dart';
part 'widgets/back_button.dart';
part 'widgets/primary_button.dart';
part 'widgets/header_text.dart';
part 'widgets/info_text.dart';
part 'widgets/clickable_info_text.dart';
part 'widgets/progress_bar.dart';
part 'widgets/success_body.dart';
part 'widgets/failure_body.dart';
part 'widgets/metadata_text.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({
    Key? key,
  }) : super(key: key);

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  @override
  void initState() {
    super.initState();
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
    final FetchFilesMetadataFailure? fetchFilesMetadataFailure =
        Provider.of<DioNotifier>(context).fetchFilesMetadataFailure;

    return Center(
      child: FailedBody(color: color, fetchFilesMetadataFailure: fetchFilesMetadataFailure!),
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
    final FetchFilesMetadataSuccess? fetchFilesMetadataSuccess =
        Provider.of<DioNotifier>(context).fetchFilesMetadataSuccess;

    return Center(
      child: SuccessBody(color: color, fetchFilesMetadataSuccess: fetchFilesMetadataSuccess!),
    );
  }
}
