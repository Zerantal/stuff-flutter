// lib/core/util/string_util.dart

String concatenateFirstTenChars(List<String> strings) {
  if (strings.isEmpty) return '';

  return strings.map((str) => str.length <= 10 ? str : str.substring(0, 10)).join('_');
}
