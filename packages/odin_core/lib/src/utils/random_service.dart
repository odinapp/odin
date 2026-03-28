import 'dart:math';

class RandomService {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

  final Random _random;

  RandomService({Random? random}) : _random = random ?? Random.secure();

  String getRandomString(int length) {
    return String.fromCharCodes(
      Iterable<int>.generate(
        length,
        (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
      ),
    );
  }
}
