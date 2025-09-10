// lib/features/container/pages/edit_container_page.dart

import 'package:flutter/material.dart';

import '../../dev_tools/pages/under_construction_page.dart';

class EditContainerPage extends StatelessWidget {
  final String? roomId;
  final String? containerId;

  const EditContainerPage({super.key, this.roomId, this.containerId});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return const UnderConstructionPage(key: ValueKey('EditContainerPage'));
  }
}
