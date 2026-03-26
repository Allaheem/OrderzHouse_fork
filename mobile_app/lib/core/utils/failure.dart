// ??? ????????
/// Domain-level failure for API/network errors. UI can show [message] safely.
class Failure {
  final String message;
  final int? statusCode;
  final String? code;

  const Failure({required this.message, this.statusCode, this.code});

  @override
  String toString() => 'Failure(message: $message, statusCode: $statusCode)';
}
