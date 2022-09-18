import 'package:flutter/material.dart';
import 'package:odin/model/config.dart';

final oApp = OApp._();

class OApp {
  OApp._();

  BuildContext? currentContext;
  Config? currentConfig;
}
