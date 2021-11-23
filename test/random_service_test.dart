import 'package:flutter_test/flutter_test.dart';
import 'package:odin/services/random_service.dart';

void main() {
  group("Random -", () {
    test("Result should be String", () {
      final RandomService _randomService = RandomService();
      final String randomText = _randomService.getRandomString(10);
      expect(randomText, isA<String>());
    });
    test("Result should be 10 char long", () {
      final RandomService _randomService = RandomService();
      final String randomText = _randomService.getRandomString(10);
      expect(randomText, hasLength(10));
    });
  });
}
