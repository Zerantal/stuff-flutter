// lib/services/exceptions/os_service_exceptions.dart

class OSServiceDisabledException implements Exception {
  final String serviceName; // e.g., "Location", "Bluetooth", "Wi-Fi"
  final String message;
  OSServiceDisabledException({required this.serviceName, required this.message});

  @override
  String toString() => 'OSServiceDisabledException ($serviceName): $message';
}
