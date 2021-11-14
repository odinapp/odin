import 'package:get_it/get_it.dart';
import 'package:odin/services/file_picker_service.dart';
import 'package:odin/services/github_service.dart';
import 'package:odin/services/random_service.dart';
import 'package:odin/services/shortner_service.dart';
import 'package:odin/services/zip_service.dart';

import 'logger.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  Stopwatch stopwatch = Stopwatch()..start();
  // locator.registerFactory<CurrentDataNotifier>(() => CurrentDataNotifier());
  locator.registerLazySingleton<GithubService>(() => GithubService());
  locator.registerLazySingleton<ShortnerService>(() => ShortnerService());
  locator.registerLazySingleton<RandomService>(() => RandomService());
  locator.registerLazySingleton<ZipService>(() => ZipService());
  locator.registerLazySingleton<FilepickerService>(() => FilepickerService());
  logger.d('Locator setup in ${stopwatch.elapsed}');
  stopwatch.stop();
}
