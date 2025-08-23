import 'package:flutter/material.dart';

class ContentsPage extends StatelessWidget {
  final ContentsScope scope;

  const ContentsPage({super.key, required this.scope});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 100);
  }
}

sealed class ContentsScope {
  const ContentsScope();
  const factory ContentsScope.all() = _AllScope;
  const factory ContentsScope.location(String locationId) = _LocationScope;
  const factory ContentsScope.room(String locationId, String roomId) = _RoomScope;
  const factory ContentsScope.container(String locationId, String roomId, String containerId) =
      _ContainerScope;
}

class _AllScope extends ContentsScope {
  const _AllScope();
}

class _LocationScope extends ContentsScope {
  const _LocationScope(this.locationId);
  final String locationId;
}

class _RoomScope extends ContentsScope {
  const _RoomScope(this.locationId, this.roomId);
  final String locationId;
  final String roomId;
}

class _ContainerScope extends ContentsScope {
  const _ContainerScope(this.locationId, this.roomId, this.containerId);
  final String locationId;
  final String roomId;
  final String containerId;
}
