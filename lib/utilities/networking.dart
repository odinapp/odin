import 'package:odin/services/logger.dart';

final oNetwork = ONetworking._();

typedef Caller<S extends RepositorySuccess, F extends RepositoryFailure> = Future<Result<S, F>> Function();

class ONetworking {
  ONetworking._();

  /// If [dealWithCommonErrorsAutomatically] is set to true,
  /// deals with client error codes [400-499] and server error codes [500-599] automatically.
  Future<Result<S, F>> call<S extends RepositorySuccess, F extends RepositoryFailure>(
    Caller<S, F> caller, {
    bool dealWithCommonErrorsAutomatically = true,
  }) async {
    final response = await caller();

    return response.resolve(
      (s) {
        return success(s);
      },
      (f) {
        final statusCode = f.statusCode;

        if (statusCode != null && dealWithCommonErrorsAutomatically) {
          if (statusCode >= 400 && statusCode <= 499) {
            // Client error
            if (f.data != null) {
              try {
                throw Exception(f.data);
              } catch (e, s) {
                logger.e(e, e, s);
              }
            }
          }

          if (statusCode >= 500 && statusCode <= 599) {
            // Server error
            if (f.data != null) {
              try {
                throw Exception(f.data);
              } catch (e, s) {
                logger.e(e, e, s);
              }
            }
          }
        }

        return failure(f);
      },
    );
  }
}

enum ApiStatus { init, loading, success, failed }

abstract class RepositoryRequest {
  const RepositoryRequest();
  Map<String, dynamic> toJson();
}

abstract class RepositorySuccess {
  String? message;

  RepositorySuccess({
    this.message,
  }) {
    message ??= '😃 Success';
  }
}

abstract class RepositoryFailure {
  String? message;
  final int? statusCode;
  final dynamic data;

  RepositoryFailure({
    this.statusCode,
    this.message,
    this.data,
  }) {
    message ??= '😯 Oops! Something went wrong.';
  }
}

abstract class Repository {}

extension IntRepositoryX on int? {
  bool get isSuccess {
    if (this != null) {
      return this! >= 200 && this! <= 299;
    } else {
      return false;
    }
  }

  bool get is404 {
    if (this != null) {
      return this! == 404;
    } else {
      return false;
    }
  }
}

Result<S, F> success<S, F>(S s) => Success<S, F>(s);
Result<S, F> failure<S, F>(F f) => Failure<S, F>(f);

// Any repository or API call can return this type.
abstract class Result<S, F> {
  const Result();

  bool isSuccess() {
    return resolve<bool>((_) => true, (_) => false);
  }

  bool isFailure() {
    return resolve<bool>((_) => false, (_) => true);
  }

  // Benefit here is that `Success` comes before `Failure`. Optimistic!
  B resolve<B>(B Function(S s) onSuccess, B Function(F f) onFailure);
}

class Failure<S, F> extends Result<S, F> {
  final F _f;

  const Failure(this._f);

  F get value => _f;

  @override
  B resolve<B>(B Function(S s) onSuccess, B Function(F f) onFailure) => onFailure(_f);
}

class Success<S, F> extends Result<S, F> {
  final S _s;

  const Success(this._s);

  S get value => _s;

  @override
  B resolve<B>(B Function(S s) onSuccess, B Function(F f) onFailure) => onSuccess(_s);
}
