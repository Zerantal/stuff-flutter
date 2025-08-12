// lib/features/location/state/edit_location_state.dart
//
// Immutable state for the Edit Location screen.

import '../../../shared/image/image_ref.dart';

class EditLocationState {
  final String name;
  final String? description;
  final String? address;

  /// UI-agnostic images the page can render directly.
  final List<ImageRef> images;

  final bool isNewLocation;
  final bool isSaving;
  final bool isPickingImage;
  final bool isGettingLocation;
  final bool deviceHasLocationService;
  final bool hasUnsavedChanges;

  const EditLocationState({
    required this.name,
    this.description,
    this.address,
    this.images = const [],
    required this.isNewLocation,
    this.isSaving = false,
    this.isPickingImage = false,
    this.isGettingLocation = false,
    this.deviceHasLocationService = true,
    this.hasUnsavedChanges = false,
  });

  EditLocationState copyWith({
    String? name,
    String? description,
    String? address,
    List<ImageRef>? images,
    bool? isNewLocation,
    bool? isSaving,
    bool? isPickingImage,
    bool? isGettingLocation,
    bool? deviceHasLocationService,
    bool? hasUnsavedChanges,
  }) {
    return EditLocationState(
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      images: images ?? this.images,
      isNewLocation: isNewLocation ?? this.isNewLocation,
      isSaving: isSaving ?? this.isSaving,
      isPickingImage: isPickingImage ?? this.isPickingImage,
      isGettingLocation: isGettingLocation ?? this.isGettingLocation,
      deviceHasLocationService: deviceHasLocationService ?? this.deviceHasLocationService,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
    );
  }
}
