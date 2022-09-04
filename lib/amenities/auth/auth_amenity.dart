import 'package:odin/amenities/auth/amenity.dart';
import 'package:odin/amenities/auth/auth_key_chain.dart';
import 'package:odin/services/logger.dart';

class AuthAmenityImpl implements AuthAmenity {
  @override
  AuthStatus authStatus = AuthStatus.unauthenticated;

  @override
  Future<void> bootUp() async {
    logger.d('[AuthAmenity.bootUp]');

    await AuthKeyChain.instance.bootUp();

    if (AuthKeyChain.instance.authenticationDetails != null) {
      authStatus = AuthStatus.authenticated;
    }

    AuthKeyChain.instance.addListener(
      () {
        logger.d('[AuthKeyChain.instance.listener] authenticated : ${authStatus == AuthStatus.authenticated}');
        if (AuthKeyChain.instance.authenticationDetails != null) {
          authStatus = AuthStatus.authenticated;
        } else {
          authStatus = AuthStatus.unauthenticated;
        }
      },
    );
  }

  @override
  void onBootUp(void data) {
    // Do nothing
    logger.d('[AuthAmenity.onBootUp]');
  }

  @override
  void bootDown() {
    logger.d('[AuthAmenity.bootDown]');

    AuthKeyChain.instance.bootDown();
  }
}
