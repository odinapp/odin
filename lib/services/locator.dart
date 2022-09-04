import 'package:get_it/get_it.dart';
import 'package:odin/constants/colors.dart';
import 'package:odin/constants/theme.dart';
import 'package:odin/providers/booter_notifier.dart';
import 'package:odin/providers/dio_notifier.dart';
import 'package:odin/router/router.dart';
import 'package:odin/services/dio_service.dart';
// import 'package:odin/services/download_service.dart';
import 'package:odin/services/encryption_service.dart';
import 'package:odin/services/environment_service.dart';
import 'package:odin/services/file_service.dart';
// import 'package:odin/services/github_service.dart';
import 'package:odin/services/odin_service.dart';
import 'package:odin/services/preferences_service.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/shortener_service.dart';
import 'package:odin/services/toast_service.dart';
import 'package:odin/services/zip_service.dart';

import 'logger.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  Stopwatch stopwatch = Stopwatch()..start();
  // locator.registerFactory<CurrentDataNotifier>(() => CurrentDataNotifier());

  // Services
  locator.registerSingleton<AppRouter>(AppRouter());
  locator.registerLazySingleton<EnvironmentService>(() => EnvironmentService());
  // locator.registerLazySingleton<GithubService>(() => GithubService());
  locator.registerLazySingleton<ShortenerService>(() => ShortenerService());
  locator.registerLazySingleton<RandomService>(() => RandomService());
  locator.registerLazySingleton<ZipService>(() => ZipService());
  locator.registerLazySingleton<FileService>(() => FileService());
  locator.registerLazySingleton<ToastService>(() => ToastService());
  locator.registerLazySingleton<PreferencesService>(() => PreferencesService());
  locator.registerLazySingleton<EncryptionService>(() => EncryptionService());
  // locator.registerLazySingleton<DownloadService>(() => DownloadService());
  locator.registerLazySingleton<DioService>(() => DioService());
  locator.registerLazySingleton<OdinService>(() => OdinService());

  // Providers
  locator.registerSingleton<DioNotifier>(DioNotifier());
  locator.registerSingleton<BooterNotifier>(BooterNotifier());

  // Globals
  locator.registerLazySingleton<OColor>(() => OColor());
  locator.registerLazySingleton<OTheme>(() => OTheme());
  logger.d('Locator setup in ${stopwatch.elapsed}');
  stopwatch.stop();
}
