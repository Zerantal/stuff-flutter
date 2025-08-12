// lib/shared/image/pick_result.dart

import 'dart:io';

/// Discriminated result for image-pick and persistence flows.
sealed class PickResult {
  const PickResult();
}

/// User cancelled the picker (or no image selected).
class PickCancelled extends PickResult {
  const PickCancelled();
}

/// Pick succeeded and we have a temp file (not yet persisted).
class PickedTemp extends PickResult {
  final File file;
  const PickedTemp(this.file);
}

/// Persist (save to store) succeeded; we return the GUID/ID.
class SavedGuid extends PickResult {
  final String guid;
  const SavedGuid(this.guid);
}

/// Something went wrong; keep the error materialized for the VM/UI.
class PickFailed extends PickResult {
  final Object error;
  final StackTrace? stackTrace;
  const PickFailed(this.error, [this.stackTrace]);
}
