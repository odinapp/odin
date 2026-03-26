abstract class Result<S, F> {
  const Result();

  B resolve<B>(
    B Function(S success) onSuccess,
    B Function(F failure) onFailure,
  );

  bool isSuccess() => resolve((_) => true, (_) => false);
}

class Success<S, F> extends Result<S, F> {
  const Success(this.value);

  final S value;

  @override
  B resolve<B>(
    B Function(S success) onSuccess,
    B Function(F failure) onFailure,
  ) {
    return onSuccess(value);
  }
}

class Failure<S, F> extends Result<S, F> {
  const Failure(this.value);

  final F value;

  @override
  B resolve<B>(
    B Function(S success) onSuccess,
    B Function(F failure) onFailure,
  ) {
    return onFailure(value);
  }
}

abstract class RepositorySuccess {
  RepositorySuccess({this.message});

  final String? message;
}

abstract class RepositoryFailure {
  RepositoryFailure({this.statusCode, this.message, this.data});

  final int? statusCode;
  final String? message;
  final dynamic data;
}

extension StatusCodeX on int? {
  bool get isSuccess => this != null && this! >= 200 && this! <= 299;
}
