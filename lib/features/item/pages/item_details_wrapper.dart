// lib/features/item/pages/item_details_wrapper.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/item_details_view_model.dart';
import 'item_details_page.dart';

class ItemDetailsWrapper extends StatefulWidget {
  final String itemId;
  final bool editable;

  const ItemDetailsWrapper({super.key, required this.itemId, required this.editable});

  @override
  State<ItemDetailsWrapper> createState() => _ItemDetailsWrapperState();
}

class _ItemDetailsWrapperState extends State<ItemDetailsWrapper> {
  late final ItemDetailsViewModel vm;

  @override
  void initState() {
    super.initState();
    // Create VM once with the initial editable state
    vm = ItemDetailsViewModel.forItem(context, itemId: widget.itemId, editable: widget.editable);
  }

  @override
  void didUpdateWidget(covariant ItemDetailsWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If editable flag changed, flip the VM instead of recreating it
    if (oldWidget.editable != widget.editable) {
      vm.isEditable = widget.editable;
    }
  }

  @override
  void dispose() {
    vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemDetailsViewModel>.value(
      value: vm,
      child: ItemDetailsPage(key: ValueKey('item_page_${widget.itemId}'), itemId: widget.itemId),
    );
  }
}
