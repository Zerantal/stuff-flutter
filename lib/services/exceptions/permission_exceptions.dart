// lib/services/exceptions/permission_exceptions.dart

// General base for any permission issue
class PermissionException implements Exception {
  final String message;
  PermissionException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

// General denial (can be subclassed or used directly)
class PermissionDeniedException extends PermissionException {
  PermissionDeniedException(super.message);
}

// General permanent denial (can be subclassed or used directly)
class PermissionDeniedPermanentlyException extends PermissionException {
  PermissionDeniedPermanentlyException(super.message);
}

// --- Location Specific Permissions ---
class LocationPermissionDeniedException extends PermissionDeniedException {
  LocationPermissionDeniedException(super.message);
}

class LocationPermissionDeniedPermanentlyException
    extends PermissionDeniedPermanentlyException {
  LocationPermissionDeniedPermanentlyException(super.message);
}
