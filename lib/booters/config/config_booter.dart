import 'package:odin/booters/booter.dart';
import 'package:odin/constants/app.dart';
import 'package:odin/providers/odin_notifier.dart';
import 'package:odin/services/locator.dart';
import 'package:odin/services/logger.dart';
import 'package:odin_core/odin_core.dart' as core;

class ConfigBooter implements Booter<void> {
  static ConfigBooter instance = ConfigBooter._();

  ConfigBooter._();

  @override
  Future<void> bootUp() async {
    logger.d('ConfigBooter.bootUp');

    await locator<core.OdinStorage>().init();
    await locator<OdinNotifier>().refreshPendingUploads();

    await locator<OdinNotifier>().fetchConfig((p0, p1) {});
    oApp.currentConfig = locator<OdinNotifier>().fetchedConfig;
  }

  @override
  void bootDown() async {
    logger.d('ConfigBooter.bootDown');
  }
}
