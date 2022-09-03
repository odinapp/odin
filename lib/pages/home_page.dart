import 'package:flutter/material.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/services/dio_service.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/locator.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const _SectionHeader(
            text: 'Upload files...',
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            onPressed: () async {
              final dummyFile = await locator<FileService>().pickSingleFile();
              if (dummyFile != null) {
                locator<DioService>().uploadFileAnonymous(dummyFile);
              }
            },
            text: 'Upload File',
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          const _SectionHeader(
            text: 'Download files...',
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              const Spacer(),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SizedBox(
                    height: 40,
                    child: TextField(
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                        ),
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                ),
              ),
              Expanded(
                child: _PrimaryButton(
                  onPressed: () async {
                    final dummyFile = await locator<FileService>().pickSingleFile();
                    if (dummyFile != null) {
                      locator<DioService>().uploadFileAnonymous(dummyFile);
                    }
                  },
                  text: 'Download',
                ),
              ),
              const Spacer(),
            ],
          )
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    Key? key,
    this.onPressed,
    required this.text,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).textTheme.bodyText1?.color?.withOpacity(0.5),
      ),
    );
  }
}
