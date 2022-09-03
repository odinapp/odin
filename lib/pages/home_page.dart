import 'package:flutter/material.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/s3_upload_service.dart';

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
        child: Center(
          child: ElevatedButton(
            onPressed: () async {
              final exampleFile = await locator<S3UploadService>().createFile();
              await locator<S3UploadService>().uploadFile(exampleFile);
            },
            child: const Text('Upload File'),
          ),
        ),
      ),
    );
  }
}
