// test/features/shared/edit/state_management_mixin_test.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:stuff/features/shared/edit/state_management_mixin.dart';

// ignore_for_file: INVALID_USE_OF_PROTECTED_MEMBER

/// Simple immutable state type for tests.
class FooState {
  final int n;
  final String s;
  const FooState(this.n, this.s);

  FooState copyWith({int? n, String? s}) => FooState(n ?? this.n, s ?? this.s);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FooState && runtimeType == other.runtimeType && n == other.n && s == other.s;

  @override
  int get hashCode => Object.hash(n, s);

  @override
  String toString() => 'FooState(n:$n,s:$s)';
}

/// A concrete VM for testing the mixin.
class TestVm extends ChangeNotifier with StateManagementMixin<FooState> {
  TestVm({bool isValidByDefault = true}) : _isValid = isValidByDefault;

  bool _isValid;
  final List<FooState> saved = [];
  Completer<void>? onSaveDelay; // allows controlling save reentrancy

  /// Allow tests to set sync validator behavior.
  set isValid(bool v) => _isValid = v;

  /// Install an async validator via configureEditEntity if desired.
  void installAsyncValidator(FutureOr<List<String>> Function(FooState) validate) {
    configureEditEntity(validate: validate);
  }

  @override
  bool isValidState() => _isValid;

  @override
  Future<void> onSaveState(FooState data) async {
    // Optional artificial delay controlled by tests.
    if (onSaveDelay != null) {
      await onSaveDelay!.future;
    }
    saved.add(data);
  }
}

void main() {
  group('StateManagementMixin', () {
    test('initialiseState sets flags and state; notifies once', () {
      final vm = TestVm();
      var ticks = 0;
      vm.addListener(() => ticks++);

      vm.initialiseState(const FooState(1, 'a'));

      expect(vm.isInitialised, isTrue);
      expect(vm.initialLoadError, isNull);
      expect(vm.currentState, const FooState(1, 'a'));
      expect(vm.originalState, const FooState(1, 'a'));
      expect(vm.hasUnsavedChanges, isFalse);
      expect(vm.validationErrors, isEmpty);
      expect(ticks, 1);
    });

    test('initialiseStateAsync success -> seeds state & notifies', () async {
      final vm = TestVm();
      var ticks = 0;
      vm.addListener(() => ticks++);

      await vm.initialiseStateAsync(() async => const FooState(2, 'b'));

      expect(vm.isInitialised, isTrue);
      expect(vm.initialLoadError, isNull);
      expect(vm.currentState, const FooState(2, 'b'));
      expect(vm.originalState, const FooState(2, 'b'));
      expect(ticks, greaterThanOrEqualTo(1)); // one before load (clear error) and one after
    });

    test('initialiseStateAsync failure -> sets initialLoadError, stays uninitialised', () async {
      final vm = TestVm();
      var ticks = 0;
      vm.addListener(() => ticks++);

      await vm.initialiseStateAsync(() async {
        throw StateError('boom');
      });

      expect(vm.isInitialised, isFalse);
      expect(vm.initialLoadError, isA<StateError>());
      expect(ticks, greaterThanOrEqualTo(1)); // notified on error
    });

    test('initialiseStateAsync respects generation; stale result ignored', () async {
      final vm = TestVm();

      final lateCompleter = Completer<FooState>();

      // 1) Kick off a "slow" init that will complete later (stale).
      final f1 = vm.initialiseStateAsync(() => lateCompleter.future);

      // 2) Kick off a second init that completes immediately (should win).
      await vm.initialiseStateAsync(() async => const FooState(9, 'new'));

      // 3) State should now reflect the second init.
      expect(vm.isInitialised, isTrue);
      expect(vm.currentState, const FooState(9, 'new'));
      expect(vm.originalState, const FooState(9, 'new'));

      // 4) Now complete the first (stale) init; it should be ignored.
      lateCompleter.complete(const FooState(0, 'stale'));
      await f1; // ensure the first call returns

      // 5) Still the new state.
      expect(vm.currentState, const FooState(9, 'new'));
      expect(vm.originalState, const FooState(9, 'new'));
    });

    test('updateState is a no-op and returns false when not initialised', () {
      final vm = TestVm();
      var ticks = 0;
      vm.addListener(() => ticks++);

      final ok = vm.updateState((s) => s.copyWith(n: 3));
      expect(ok, isFalse);
      expect(ticks, 0);
      expect(vm.isInitialised, isFalse);
    });

    test('setCurrentState updates only when changed; notifies accordingly', () {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));
      var ticks = 0;
      vm.addListener(() => ticks++);

      // Equal -> no notify
      final same = vm.setCurrentState(const FooState(1, 'a'));
      expect(same, isTrue);
      expect(ticks, 0);

      // Different -> notify once
      final changed = vm.setCurrentState(const FooState(2, 'a'));
      expect(changed, isTrue);
      expect(vm.currentState, const FooState(2, 'a'));
      expect(ticks, 1);
    });

    test('updateState mutates when initialised', () {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));
      var ticks = 0;
      vm.addListener(() => ticks++);

      final ok = vm.updateState((s) => s.copyWith(n: s.n + 1));
      expect(ok, isTrue);
      expect(vm.currentState, const FooState(2, 'a'));
      expect(vm.hasUnsavedChanges, isTrue);
      expect(ticks, 1);
    });

    test('hasUnsavedChanges honors injected equals', () {
      final vm = TestVm()
        ..configureEditEntity(
          equals: (a, b) => a.s == b.s, // ignore `n` differences
        )
        ..initialiseState(const FooState(1, 'k'));

      expect(vm.hasUnsavedChanges, isFalse);
      vm.updateState((s) => s.copyWith(n: 999)); // different n, same s
      expect(vm.hasUnsavedChanges, isFalse);
      vm.updateState((s) => s.copyWith(s: 'changed'));
      expect(vm.hasUnsavedChanges, isTrue);
    });

    test('replaceOriginal respects keepCurrent and notify flag', () {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));
      var ticks = 0;
      vm.addListener(() => ticks++);

      // Keep current -> only original changes
      final ok1 = vm.replaceOriginal(const FooState(2, 'b'), keepCurrent: true, notify: true);
      expect(ok1, isTrue);
      expect(vm.originalState, const FooState(2, 'b'));
      expect(vm.currentState, const FooState(1, 'a'));
      expect(ticks, 1);

      // Replace both
      final ok2 = vm.replaceOriginal(const FooState(3, 'c'), keepCurrent: false, notify: true);
      expect(ok2, isTrue);
      expect(vm.originalState, const FooState(3, 'c'));
      expect(vm.currentState, const FooState(3, 'c'));
      expect(ticks, 2);
    });

    test('cancel reverts to original', () {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));
      vm.updateState((s) => s.copyWith(n: 5));
      expect(vm.currentState, const FooState(5, 'a'));

      vm.cancel();
      expect(vm.currentState, const FooState(1, 'a'));
      expect(vm.hasUnsavedChanges, isFalse);
    });

    test('saveState (sync validator path) blocks when invalid; succeeds when valid', () async {
      final vm = TestVm(isValidByDefault: false)..initialiseState(const FooState(1, 'a'));
      var ticks = 0;
      vm.addListener(() => ticks++);

      // invalid -> no save
      final r1 = await vm.saveState();
      expect(r1, isFalse);
      expect(vm.saved, isEmpty);

      // make it valid -> save
      vm.isValid = true;
      final r2 = await vm.saveState();
      expect(r2, isTrue);
      expect(vm.saved.single, const FooState(1, 'a'));
      expect(vm.originalState, const FooState(1, 'a'));
      expect(vm.validationErrors, isEmpty);
      expect(vm.isSaving, isFalse);
      expect(ticks, greaterThanOrEqualTo(1)); // notified entering/leaving save
    });

    test('saveState (async validator path) surfaces errors and skips save', () async {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));
      vm.installAsyncValidator((state) async {
        return state.n < 10 ? <String>['n too small'] : const <String>[];
      });

      final r1 = await vm.saveState();
      expect(r1, isFalse);
      expect(vm.validationErrors, isNotEmpty);
      expect(vm.saved, isEmpty);

      vm.updateState((s) => s.copyWith(n: 42));
      final r2 = await vm.saveState();
      expect(r2, isTrue);
      expect(vm.validationErrors, isEmpty);
      expect(vm.saved.length, 1);
    });

    test('saveState is not re-entrant (second call returns false while saving)', () async {
      final vm = TestVm()..initialiseState(const FooState(1, 'a'));

      // Make onSaveState wait so we can call saveState twice.
      vm.onSaveDelay = Completer<void>();

      final first = vm.saveState();
      expect(vm.isSaving, isTrue);

      final second = await vm.saveState();
      expect(second, isFalse, reason: 're-entrant save must be rejected');

      // Finish the first save
      vm.onSaveDelay!.complete();
      await first;

      expect(vm.isSaving, isFalse);
      expect(vm.saved.length, 1);
    });

    test('clearInitialLoadError notifies and sets error to null', () async {
      final vm = TestVm();
      var ticks = 0;
      vm.addListener(() => ticks++);

      await vm.initialiseStateAsync(() async => throw Exception('x'));
      expect(vm.initialLoadError, isNotNull);

      vm.clearInitialLoadError();
      expect(vm.initialLoadError, isNull);
      expect(ticks, greaterThanOrEqualTo(2));
    });
  });
}
