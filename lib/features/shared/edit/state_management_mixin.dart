// lib/features/shared/edit/state_management_mixing.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

Logger _log = Logger('StateManagementMixin');

/// View usage guide:
/// Show a spinner when !vm.isInitialised && vm.initialLoadError == null.
/// Show an error/retry UI when !vm.isInitialised && vm.initialLoadError != null.
/// Render the form when vm.isInitialised.
/// Disable save when !vm.isInitialised || vm.isSaving.
mixin StateManagementMixin<T> on ChangeNotifier {
  late T _originalState;
  late T _currentState;

  bool _isInitialised = false; // true once a real state is set
  bool _isSaving = false;
  Object? _initialLoadError;
  bool _isEditable = true; // default editable

  // in case '==' not defined on state type
  bool Function(T a, T b)? _equals;

  FutureOr<List<String>> Function(T state)? _validate;
  List<String> _validationErrors = const [];

  // For race protection (ignore stale responses)
  int _loadGeneration = 0;

  // ---------------------------------------------------------------------------
  // Public surface
  // ---------------------------------------------------------------------------

  /// Whether this VM allows editing/mutating operations.
  /// Default is true. Override in your VM to bind to an internal flag.
  bool get isEditable => _isEditable;

  /// Change editability. When set to false, mutators become no-ops.
  set isEditable(bool value) {
    if (_isEditable == value) return;
    _isEditable = value;

    // Only fire hook + notify if state is already initialised
    if (_isInitialised) {
      onChangeIsEditableState(value);
      notifyListeners();
    }
  }

  bool get isInitialised => _isInitialised;
  bool get isSaving => _isSaving;
  Object? get initialLoadError => _initialLoadError;

  T get currentState => _currentState;
  T get originalState => _originalState;

  List<String> get validationErrors => _validationErrors;

  bool get hasUnsavedChanges => isInitialised && !_areEqual(_currentState, _originalState);

  // call this once in constructor if custom behaviour required
  @protected
  void configureEditEntity({
    bool Function(T a, T b)? equals,
    FutureOr<List<String>> Function(T state)? validate,
  }) {
    _equals = equals;
    _validate = validate;
  }

  /// Synchronous init when you already have the real data.
  @protected
  void initialiseState(T data, {bool notify = true}) {
    _originalState = data;
    _currentState = data;
    _validationErrors = const [];
    _initialLoadError = null;
    _isInitialised = true;
    if (notify) notifyListeners();
  }

  /// Asynchronous init from DB/remote. Loads the **real** state and sets both
  /// original & current to that value. No placeholders, no preserve-edits.
  Future<void> initialiseStateAsync(Future<T> Function() loader) async {
    final gen = ++_loadGeneration;

    _initialLoadError = null;
    notifyListeners();

    try {
      final loaded = await loader();
      if (gen != _loadGeneration) return; // stale

      _originalState = loaded;
      _currentState = loaded;
      _initialLoadError = null;
      _isInitialised = true;
      notifyListeners();
    } catch (e) {
      if (gen != _loadGeneration) return; // stale
      _initialLoadError = e;
      _isInitialised = false;
      notifyListeners();
    }
  }

  /// Replace the "baseline" (e.g., after a successful save or external refresh).
  /// Optionally also replace the current state.
  @protected
  bool replaceOriginal(T data, {bool keepCurrent = true, bool notify = false}) {
    if (!_ensureInitialised('replaceOriginal')) return false;
    if (!isEditable) return false; // 🚫 prevent replacement in view-only mode

    _originalState = data;
    if (!keepCurrent) {
      _currentState = data;
    }
    if (notify) notifyListeners();

    return true;
  }

  /// Assign a new current state. No notify if unchanged.
  @protected
  bool setCurrentState(T next, {bool notify = true}) {
    if (!_ensureInitialised('setCurrentState')) return false;
    if (!isEditable) return false; // 🚫 ignore in view-only mode

    if (_areEqual(next, _currentState)) return true;
    _currentState = next;
    if (notify) notifyListeners();

    return true;
  }

  @protected
  bool updateState(T Function(T current) build, {bool notify = true}) {
    if (!_ensureInitialised('updateState')) return false;
    if (!isEditable) return false; // 🚫 ignore in view-only mode

    setCurrentState(build(_currentState), notify: notify);
    return true;
  }

  /// Attempts to validate then save the current state.
  /// Returns true on success (including when nothing to save due to invalid).
  Future<bool> saveState() async {
    if (!_ensureInitialised('saveState')) return false;
    if (!isEditable) return false; // 🚫 block saves in view-only mode

    if (_isSaving) return false;

    // Prefer the async validator if supplied; otherwise fall back to isValidState().
    if (_validate != null) {
      final errs = await _validate!(_currentState);
      _validationErrors = errs;
      if (errs.isNotEmpty) {
        notifyListeners(); // surface errors
        return false;
      }
    } else if (!isValidState()) {
      return false;
    }

    _isSaving = true;
    notifyListeners();
    try {
      await onSaveState(_currentState);
      _originalState = _currentState;
      _validationErrors = const [];
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // for retrying initialisation
  @protected
  void clearInitialLoadError() {
    _initialLoadError = null;

    notifyListeners();
  }

  /// Revert to the original state.
  void cancel({bool notify = true}) {
    if (!_ensureInitialised('cancel')) return;

    setCurrentState(_originalState, notify: notify);
  }

  // ---------------------------------------------------------------------------
  // Hooks to override/implement in VM
  // ---------------------------------------------------------------------------

  /// Legacy/simple validation hook. If you prefer richer errors, provide
  /// `configureEditEntity(validate: ...)` instead and ignore this.
  @protected
  bool isValidState() => true;

  /// Persist the state. Implement this in your VM.
  @protected
  Future<void> onSaveState(T data);

  @protected
  void onChangeIsEditableState(bool isEditable) {}

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  bool _areEqual(T a, T b) {
    final eq = _equals;
    if (eq != null) return eq(a, b);
    return a == b;
  }

  @protected
  bool _ensureInitialised(String caller) {
    if (_isInitialised) return true;
    assert(() {
      _log.warning('$runtimeType.$caller called before initialiseState; ignoring.');
      return true;
    }());

    return false;
  }
}
