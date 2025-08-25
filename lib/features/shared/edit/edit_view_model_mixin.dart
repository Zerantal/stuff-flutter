// lib/features/shared/edit/edit_view_model_mixin.dart


import 'package:flutter/foundation.dart';

mixin EditViewModelMixin on ChangeNotifier
{
  // bool _hasTempSession = false;
  bool _isInitialised = false;

  bool get isInitialised => _isInitialised;

  void setIsInitialised(bool v) {
    if (_isInitialised == v) return;
    _isInitialised = v;
    notifyListeners();
  }
}

// // lib/features/shared/edit/edit_page_core.dart
// //
// // Core mixin for edit pages that stage images in a TempSession and persist them
// // on save. Keeps identifiers and ImageRefs index-aligned with the UI.
// //
// // VM only needs to:
// //   - provide `state` with copyWith(images, isSaving, hasUnsavedChanges, hasTempSession)
// //   - implement three hooks: refsForGuids, persistTempFile, deleteGuids
// //   - call initEditSession(...), wire ImageManagerInput's callbacks, and call saveWithImages(...)
//
// import 'dart:async';
// import 'dart:io';
//
// import 'package:flutter/foundation.dart';
// import 'package:flutter/widgets.dart';
//
// import '../../../core/image_identifier.dart';
// import '../../../shared/image/image_ref.dart';
// import '../../../services/contracts/temporary_file_service_interface.dart';
// import '../../../shared/image/image_identifier_persistence.dart' as persist;
//
// mixin EditViewModelMixin<S> on ChangeNotifier {
//   // ----- VM contract -----
//   S get state;
//   set state(S value);
//
//   /// Map persisted GUIDs to UI-ready ImageRefs (order preserved).
//   @protected
//   Future<List<ImageRef>> refsForGuids(List<String> guids);
//
//   /// Persist a staged temp file into your permanent store; return its GUID ("guid.ext").
//   @protected
//   Future<String> persistTempFile(File temp);
//
//   /// Delete previously-persisted images by GUID (best-effort).
//   @protected
//   Future<void> deleteGuids(List<String> guids);
//
//   // ----- Internal state shared across edit pages -----
//   TempSession? _tempSession;
//   TempSession? get tempSession => _tempSession;
//
//   final List<ImageIdentifier> _imageIds = <ImageIdentifier>[];
//   List<ImageIdentifier> get imageIds => List.unmodifiable(_imageIds);
//
//   final Set<String> _previousGuids = <String>{};
//
//   bool _isInitialising = false;
//   bool get isInitialising => _isInitialising;
//
//   final List<TextEditingController> _registeredControllers = <TextEditingController>[];
//
//   // ===========================================================================
//   // State helpers
//   // ===========================================================================
//   @protected
//   void update(S Function(S current) build) {
//     state = build(state);
//     notifyListeners();
//   }
//
//   @protected
//   void markDirty() {
//     update((s) => (s as dynamic).copyWith(hasUnsavedChanges: true) as S);
//   }
//
//   void setInitialising(bool v) {
//     if (_isInitialising == v) return;
//     _isInitialising = v;
//     notifyListeners();
//   }
//
//   /// Optional convenience: automatically mark dirty when any text changes.
//   /// Call once in init and remember to call [unregisterTextControllers] (e.g., in dispose).
//   void registerTextControllers(List<TextEditingController> ctrls) {
//     for (final c in ctrls) {
//       c.addListener(_onAnyFieldChanged);
//       _registeredControllers.add(c);
//     }
//   }
//
//   void unregisterTextControllers() {
//     for (final c in _registeredControllers) {
//       c.removeListener(_onAnyFieldChanged);
//     }
//     _registeredControllers.clear();
//   }
//
//   void _onAnyFieldChanged() {
//     if (_isInitialising) return;
//     markDirty();
//   }
//
//   // ===========================================================================
//   // Session & seeding
//   // ===========================================================================
//   Future<void> initEditSession({
//     required ITemporaryFileService tempFiles,
//     required String label,
//     List<String>? existingGuids,
//   }) async {
//     setInitialising(true);
//     try {
//       _tempSession = await tempFiles.startSession(label: label);
//       update((s) => (s as dynamic).copyWith(hasTempSession: true) as S);
//
//       _imageIds.clear();
//       _previousGuids.clear();
//
//       if (existingGuids != null && existingGuids.isNotEmpty) {
//         final refs = await refsForGuids(existingGuids);
//         _previousGuids.addAll(existingGuids);
//         for (final g in existingGuids) {
//           _imageIds.add(GuidIdentifier(g));
//         }
//         update((s) => (s as dynamic).copyWith(
//           images: refs,
//           hasUnsavedChanges: false,
//         ) as S);
//       }
//     } finally {
//       setInitialising(false);
//     }
//   }
//
//   Future<void> disposeTempSession({bool deleteContents = true}) async {
//     final s = _tempSession;
//     if (s == null) return;
//     try {
//       await s.dispose(deleteContents: deleteContents);
//     } finally {
//       _tempSession = null;
//       update((st) => (st as dynamic).copyWith(hasTempSession: false) as S);
//     }
//   }
//
//   // ===========================================================================
//   // Image list operations (index-aligned with state.images)
//   // ===========================================================================
//   /// Wire this to ImageManagerInput.onImagePicked.
//   void addImageFromPicker(ImageIdentifier id, ImageRef ref) {
//     _imageIds.add(id);
//     update((s) {
//       final refs = List<ImageRef>.from((s as dynamic).images as List<ImageRef>)..add(ref);
//       return (s as dynamic).copyWith(images: refs, hasUnsavedChanges: true) as S;
//     });
//   }
//
//   /// Wire this to ImageManagerInput.onRemoveAt.
//   void removeImageAt(int index) {
//     final refs = (state as dynamic).images as List<ImageRef>;
//     if (index < 0 || index >= refs.length) return;
//     final nextRefs = List<ImageRef>.from(refs)..removeAt(index);
//     if (index < _imageIds.length) {
//       _imageIds.removeAt(index);
//     }
//     update((s) => (s as dynamic).copyWith(images: nextRefs, hasUnsavedChanges: true) as S);
//   }
//
//   /// Optional helper if your UI supports reordering.
//   void reorderImages(int oldIndex, int newIndex) {
//     final refs = List<ImageRef>.from((state as dynamic).images as List<ImageRef>);
//     if (oldIndex < newIndex) newIndex -= 1;
//     final ref = refs.removeAt(oldIndex);
//     refs.insert(newIndex, ref);
//
//     final id = _imageIds.removeAt(oldIndex);
//     _imageIds.insert(newIndex, id);
//
//     update((s) => (s as dynamic).copyWith(images: refs, hasUnsavedChanges: true) as S);
//   }
//
//   // ===========================================================================
//   // Temp ➜ GUID persistence
//   // ===========================================================================
//
//   List<String> currentGuids() =>
//       _imageIds.whereType<GuidIdentifier>().map((g) => g.guid).toList(growable: false);
//
//   // ===========================================================================
//   // Save orchestration
//   // ===========================================================================
//   /// Full save pipeline:
//   ///  - guards with `isSaving`
//   ///  - persists temp images ➜ GUIDs (order preserved)
//   ///  - invokes your [persistEntity] with final GUID list
//   ///  - deletes orphans removed during editing (best-effort)
//   ///  - marks clean & disposes the temp session
//   Future<R?> saveWithImages<R>({
//     required Future<R> Function(List<String> guids) persistEntity,
//     bool cleanupOrphans = true,
//     bool disposeSessionAfter = true,
//   }) async {
//     final alreadySaving = (state as dynamic).isSaving as bool;
//     if (alreadySaving) return null;
//
//     update((s) => (s as dynamic).copyWith(isSaving: true) as S);
//     try {
//       // 1) Persist temps ➜ GUIDs
//       final guids = await persist.persistTempImages();
//
//       // 2) Persist the entity
//       final result = await persistEntity(guids);
//
//       // 3) Cleanup removed persisted images
//       if (cleanupOrphans) {
//         final finalSet = guids.toSet();
//         final removed = _previousGuids.difference(finalSet).toList();
//         if (removed.isNotEmpty) {
//           try {
//             await deleteGuids(removed);
//           } catch (_) {
//             // Best-effort: swallow cleanup errors
//           }
//         }
//         _previousGuids
//           ..clear()
//           ..addAll(finalSet);
//       }
//
//       // 4) Mark clean & close session
//       update((s) => (s as dynamic).copyWith(hasUnsavedChanges: false) as S);
//       if (disposeSessionAfter) {
//         await disposeTempSession(deleteContents: true);
//       }
//
//       return result;
//     } finally {
//       update((s) => (s as dynamic).copyWith(isSaving: false) as S);
//     }
//   }
// }
