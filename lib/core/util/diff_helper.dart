// lib/shared/debug/diff_helper.dart
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kDebugMode, listEquals, debugPrint;

/// Lightweight logger you can use in shouldRebuild blocks.
class DiffLogger {
  final String tag;
  final bool enabled;
  const DiffLogger({this.tag = 'Diff', bool? enabled}) : enabled = enabled ?? kDebugMode;

  void call(String message) {
    if (enabled) debugPrint('[$tag] $message');
  }
}

/// Short identity string for objects (useful when they don't have nice toString).
String shortId(Object? o) =>
    o == null ? 'null' : '${o.runtimeType}@${o.hashCode.toRadixString(16)}';

/// A compact hash string for lists
String listHash<T>(List<T> xs) => '${xs.length}@${Object.hashAll(xs)}';

/// Diff two scalar values using ==. Logs when they differ.
bool diffScalar<T>(DiffLogger log, String label, T a, T b) {
  if (a != b) {
    log('$label: $a -> $b');
    return true;
  }
  return false;
}

/// Diff identity (not equality) — logs when object *instance* changes.
bool diffIdentity(DiffLogger log, String label, Object? a, Object? b) {
  if (!identical(a, b)) {
    log('$label (identity): ${shortId(a)} -> ${shortId(b)}');
    return true;
  }
  return false;
}

/// Order-sensitive list diff (uses == per element). Logs size/hash and a few index-level diffs.
bool diffList<T>(
  DiffLogger log,
  String label,
  List<T> a,
  List<T> b, {
  int sample = 5,
  String Function(T value)? fmt,
}) {
  bool changed = false;
  if (identical(a, b)) return false;

  if (!listEquals(a, b)) {
    changed = true;
    log('$label changed: ${listHash(a)} -> ${listHash(b)}');

    // Show per-index differences (first few only)
    final n = math.min(math.min(a.length, b.length), sample);
    for (var i = 0; i < n; i++) {
      final ai = a[i], bi = b[i];
      if (ai != bi) {
        final fai = fmt != null ? fmt(ai) : '$ai';
        final fbi = fmt != null ? fmt(bi) : '$bi';
        log('  $label[$i]: $fai -> $fbi');
      }
    }
    if (a.length != b.length) {
      log('  $label length: ${a.length} -> ${b.length}');
    }
  }
  return changed;
}

/// Set-style diff (order-insensitive). Useful when your elements have stable equality/hashCode.
bool diffSet<T>(
  DiffLogger log,
  String label,
  Iterable<T> a,
  Iterable<T> b, {
  int sample = 8,
  String Function(T value)? fmt,
}) {
  final as = a is Set<T> ? a : a.toSet();
  final bs = b is Set<T> ? b : b.toSet();
  final added = bs.difference(as);
  final removed = as.difference(bs);

  if (added.isEmpty && removed.isEmpty) return false;

  String fmtItem(T v) => fmt != null ? fmt(v) : '$v';
  String listFew(Iterable<T> it) =>
      it.take(sample).map(fmtItem).join(', ') + (it.length > sample ? ' …' : '');

  if (added.isNotEmpty) {
    log('$label +added (${added.length}): ${listFew(added)}');
  }
  if (removed.isNotEmpty) {
    log('$label -removed (${removed.length}): ${listFew(removed)}');
  }
  return true;
}
