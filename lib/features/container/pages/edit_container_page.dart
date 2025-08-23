// lib/features/container/pages/edit_container_page.dart

import 'package:flutter/material.dart';

class EditContainerPage extends StatelessWidget {
  final String locationId;
  final String roomId;
  final String? containerId;

  const EditContainerPage({
    super.key,
    required this.locationId,
    required this.roomId,
    this.containerId,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
