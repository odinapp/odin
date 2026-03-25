import 'package:flutter_test/flutter_test.dart';
import 'package:odin/services/shortener_service.dart';

void main() {
  group("Shortener -", () {
    test("Built short URL contains shrtco.de", () {
      final ShortenerService shortenerService = ShortenerService();
      final built = shortenerService.getShortUrlFromFileCode("abc123test");
      expect(
        built,
        stringContainsInOrder(["https://", "shrtco.de", "abc123test"]),
      );
    });
  });
}
