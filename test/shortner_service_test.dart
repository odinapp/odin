import 'package:flutter_test/flutter_test.dart';
import 'package:odin/services/shortener_service.dart';

void main() {
  group("Shortener -", () {
    test("Url should contain shrtco.de", () async {
      final ShortenerService shortnerService = ShortenerService();
      const String url = "https://www.google.com";
      final String? shortUrl = await shortnerService.getFileCode(url, "test");
      expect(shortUrl, stringContainsInOrder(["https://", "shrtco.de"]));
    });
  });
}
