// ??? ????????
import 'failure.dart';

/// Result type: either success [T] or [Failure]. No exceptions in data/domain layer.
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

final class Fail<T> extends Result<T> {
  final Failure failure;
  const Fail(this.failure);
}

extension ResultExtension<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Fail<T>;
  T? get valueOrNull => switch (this) {
    Success(:final data) => data,
    Fail() => null,
  };
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Fail(:final failure) => failure,
  };
}
