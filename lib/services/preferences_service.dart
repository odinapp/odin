import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  late final SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  bool getUniversalShare() {
    bool? universalShare = _preferences.getBool('universalShare');
    if (universalShare == null) {
      universalShare = false;
      _preferences.setBool('universalShare', universalShare);
    }
    return universalShare;
  }

  void setUniversalShare(bool value) {
    _preferences.setBool('universalShare', value);
  }
}
