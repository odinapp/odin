import 'package:odin/booters/booter.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';

class ConfigBooter implements Booter<void> {
  static ConfigBooter instance = ConfigBooter._();

  ConfigBooter._();

  @override
  Future<void> bootUp() async {
    logger.d('ConfigBooter.bootUp');

    await locator<DioNotifier>().fetchConfig((p0, p1) {});
    oApp.currentConfig = locator<DioNotifier>().fetchConfigSuccess?.config;
  }

  @override
  void bootDown() async {
    logger.d('ConfigBooter.bootDown');
  }
}
