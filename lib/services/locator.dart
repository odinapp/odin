import 'package:get_it/get_it.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/theme.dart';
import 'package:odin/providers/booter_notifier.dart';
import 'package:odin/providers/odin_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/odin_storage_impl.dart';
import 'package:odin/services/toast_service.dart';
import 'package:odin_core/odin_core.dart' as core;

import 'logger.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  Stopwatch stopwatch = Stopwatch()..start();

  // Services
  locator.registerSingleton<AppRouter>(AppRouter());
  locator.registerLazySingleton<EnvironmentService>(() => EnvironmentService());
  locator.registerLazySingleton<FileService>(() => FileService());
  locator.registerLazySingleton<ToastService>(() => ToastService());
  locator.registerLazySingleton<core.OdinStorage>(() => OdinStorageImpl());

  // Providers
  locator.registerSingleton<OdinNotifier>(OdinNotifier());
  locator.registerSingleton<BooterNotifier>(BooterNotifier());

  // Globals
  locator.registerLazySingleton<OColor>(() => OColor());
  locator.registerLazySingleton<OTheme>(() => OTheme());
  logger.d('Locator setup in ${stopwatch.elapsed}');
  stopwatch.stop();
}
