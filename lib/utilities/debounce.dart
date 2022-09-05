import 'dart:async';

class ODebounce {
  Duration delay;
  Timer? _timer;

  ODebounce(
    this.delay,
  );

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void dispose() {
    _timer?.cancel();
  }
}
