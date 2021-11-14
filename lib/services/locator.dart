import 'package:get_it/get_it.dart';
import 'package:odin/services/data_service.dart';
import 'package:odin/services/shortner_service.dart';

import 'logger.dart';

GetIt locator = GetIt.instance;

Future<void> setupLocator() async {
  Stopwatch stopwatch = Stopwatch()..start();
  // locator.registerFactory<CurrentDataNotifier>(() => CurrentDataNotifier());
  locator.registerLazySingleton<DataService>(() => DataService());
  locator.registerLazySingleton<ShortnerService>(() => ShortnerService());
  logger.d('Locator setup in ${stopwatch.elapsed}');
  stopwatch.stop();
}
