import 'package:flutter/material.dart';
import 'package:odin/services/booter_service.dart';

enum AppBootStatus { booting, booted }

class BooterNotifier with ChangeNotifier {
  final BooterService _booterService = BooterService();

  BooterNotifier() {
    bootUp();
  }

  set appBootStatus(AppBootStatus? value) {
    _booterService.appBootStatus = value ?? AppBootStatus.booting;
    notifyListeners();
  }

  Stream<AppBootStatus> get appBootStatusStream => _booterService.appBootStatusStream;
  AppBootStatus? get appBootStatus => _booterService.appBootStatusStream.valueOrNull;

  Future<void> bootUp() async {
    await _booterService.bootUp();
    notifyListeners();
  }

  Future<void> bootDown() async {
    await _booterService.bootDown();
  }
}
