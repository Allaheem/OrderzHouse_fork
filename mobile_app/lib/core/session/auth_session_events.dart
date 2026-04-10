import 'dart:async';

/// Fired when the backend rejects the session (invalid/expired JWT). [AuthNotifier] listens and runs [logout].
final StreamController<void> authSessionInvalidated =
    StreamController<void>.broadcast();
