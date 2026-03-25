import 'package:flutter/widgets.dart';

bool isMobileLayout(BuildContext context) =>
    MediaQuery.of(context).size.width < 600;
