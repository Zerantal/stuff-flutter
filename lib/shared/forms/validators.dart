// lib/shared/forms/validators.dart
typedef StrValidator = String? Function(String?);

StrValidator requiredMax(int max) => (v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return 'Required';
  if (s.length > max) return 'Keep it under $max characters';
  return null;
};

StrValidator optionalMax(int max) => (v) {
  final s = (v ?? '').trim();
  if (s.isEmpty) return null;
  if (s.length > max) return 'Keep it under $max characters';
  return null;
};
