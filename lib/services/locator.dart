import 'package:get_it/get_it.dart';
import 'package:odin/services/file_service.dart';
import 'package:odin/services/github_service.dart';
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
  locator.registerLazySingleton<GithubService>(() => GithubService());
  locator.registerLazySingleton<ShortenerService>(() => ShortenerService());
  locator.registerLazySingleton<RandomService>(() => RandomService());
  locator.registerLazySingleton<ZipService>(() => ZipService());
  locator.registerLazySingleton<FileService>(() => FileService());
  locator.registerLazySingleton<ToastService>(() => ToastService());
  locator.registerLazySingleton<PreferencesService>(() => PreferencesService());
  logger.d('Locator setup in ${stopwatch.elapsed}');
  stopwatch.stop();
}
