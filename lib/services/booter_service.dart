import 'dart:collection';

import 'package:odin/booters/config/config_booter.dart';
import 'package:odin/booters/core_amenities/amenities_booter.dart';
import 'package:odin/providers/booter_notifier.dart';
import 'package:odin/services/logger.dart';
import 'package:rxdart/rxdart.dart';

class BooterService {
  final _appBootStatusSubject = BehaviorSubject<AppBootStatus>.seeded(AppBootStatus.booting);

  ValueStream<AppBootStatus> get appBootStatusStream => _appBootStatusSubject.stream;

  set appBootStatus(AppBootStatus v) => _appBootStatusSubject.add(v);

  Future<void> bootUp() async {
    // Fast booter must be booted before other booters since it' used in other booters
    // Eg, CurrentProfileBooter
    final preBootUpSequence = UnmodifiableListView([
      AmenitiesBooter.instance.bootUp().then((_) => logger.d('AmenitiesBooter preBoot Finished')),
    ]);

    await Future.wait(preBootUpSequence);

    final bootUpProcesses = [
      ConfigBooter.instance.bootUp(),
    ];

    await Future.wait(bootUpProcesses);

    appBootStatus = AppBootStatus.booted;

    logger.d('booted up');
    _onBootedUp();
  }

  Future<void> bootDown() async {
    AmenitiesBooter.instance.bootDown();
  }

  void _onBootedUp() async {}
}
