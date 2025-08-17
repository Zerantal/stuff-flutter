import 'dart:convert';
import 'package:drift/drift.dart';

/// Store [List<String>] as JSON text in SQLite.
class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) {
    final raw = jsonDecode(fromDb);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
