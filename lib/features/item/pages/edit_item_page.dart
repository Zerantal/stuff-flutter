// lib/features/item/pages/item_details_page.dart

import 'package:flutter/material.dart';

class ItemDetailsPage extends StatelessWidget {
  final String? locationId;
  final String? roomId;
  final String? containerId;
  final String? itemId;

  const ItemDetailsPage.addToContainer({
    super.key,
    required this.locationId,
    required this.roomId,
    required this.containerId,
  }) : itemId = null;

  const ItemDetailsPage.addToRoom({super.key, required this.locationId, required this.roomId})
    : itemId = null,
      containerId = null;

  const ItemDetailsPage.view({super.key, required this.itemId})
    : locationId = null,
      roomId = null,
      containerId = null;

  const ItemDetailsPage.edit({super.key, required this.itemId})
    : locationId = null,
      roomId = null,
      containerId = null;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}
