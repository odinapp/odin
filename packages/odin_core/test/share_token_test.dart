import 'package:odin_core/odin_core.dart';
import 'package:test/test.dart';

void main() {
  group('parseShareToken', () {
    test('parses 8-char code', () {
      final token = parseShareToken('aB3kR9mQ');
      expect(token.fileCode, 'aB3kR9mQ');
    });

    test('rejects non-8-char code', () {
      expect(() => parseShareToken('short'), throwsA(isA<FormatException>()));
    });

    test('rejects URL token', () {
      expect(
        () => parseShareToken('https://getodin.com/d/aB3kR9mQ'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
