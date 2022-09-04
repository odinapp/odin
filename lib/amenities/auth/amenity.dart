import 'package:odin/amenities/amenity.dart';
import 'package:odin/amenities/auth/auth_amenity.dart';

enum AuthStatus { authenticated, unauthenticated }

abstract class AuthAmenity extends Amenity<void> {
  static final AuthAmenity instance = AuthAmenityImpl();

  AuthAmenity._();

  AuthStatus get authStatus;
}
