import 'dart:io';
import 'package:drift/native.dart';
// import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'database.dart';

Future<AppDatabase> openAppDatabase({String fileName = 'stuff.sqlite'}) async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File(p.join(dir.path, fileName));
  // Background isolate friendly:
  return AppDatabase(NativeDatabase.createInBackground(file));
}
