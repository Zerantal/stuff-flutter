import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/location/pages/locations_page.dart'; // <-- import your LocationsPage
import '../../../shared/image/image_ref.dart';
import '../../../shared/widgets/entity_description.dart';
import '../../../shared/widgets/image_thumb.dart';
import '../../../shared/widgets/responsive_entity_sliver.dart'; // your widget

class EntityDemo {
  final String title;
  final String description;
  final IconData icon;
  EntityDemo(this.title, this.description, this.icon);
}

class ResponsiveEntitySliverDemoPage extends StatefulWidget {
  const ResponsiveEntitySliverDemoPage({super.key});

  @override
  State<ResponsiveEntitySliverDemoPage> createState() => _ResponsiveEntitySliverDemoPageState();
}

class _ResponsiveEntitySliverDemoPageState extends State<ResponsiveEntitySliverDemoPage> {
  // Parameters with defaults
  double gridBreakpoint = 720;
  bool snapToTileWidth = true;
  SnapAlign snapAlign = SnapAlign.left;
  double gridTileWidth = 240;
  int gridMinColumns = 2;
  int gridMaxColumns = 8;

  double? gridHeaderHeight;
  double? gridBodyHeight;
  double? gridTrailingHeight;
  double? gridSectionGap;
  double? gridTileVerticalPadding;

  EdgeInsets gridPadding = const EdgeInsets.fromLTRB(12, 12, 12, 12);
  double gridMainAxisSpacing = 12;
  double gridCrossAxisSpacing = 12;

  double? listTileMinHeight;
  EdgeInsets listPadding = const EdgeInsets.only(top: 8, bottom: 8);

  String lorem =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.';

  Random r = Random(44);

  // Dummy data
  late final items = List.generate(11, (i) {
    final l = r.nextInt(95) + 10;
    return EntityDemo('Item $i', 'Description for item $i: ${lorem.substring(10, l)}', Icons.star);
  });

  @override
  Widget build(BuildContext context) {
    final placeholderImage = const ImageThumb(
      image: ImageRef.asset('assets/images/image_placeholder.png'),
      width: 80,
      height: 80,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("ResponsiveEntitySliver Playground"),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined), // Or Icons.apps, Icons.dashboard_outlined
            tooltip: 'Go to Main App',
            onPressed: () {
              StatefulNavigationShell.of(context).goBranch(0);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left side: LocationsPage
          const Expanded(child: LocationsPage()),
          const VerticalDivider(width: 1),
          // Right side: Demo
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 0,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Controls",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        _slider(
                          "Grid Breakpoint",
                          gridBreakpoint,
                          400,
                          1200,
                          (v) => setState(() => gridBreakpoint = v),
                        ),
                        SwitchListTile(
                          title: const Text("Snap To Tile Width"),
                          value: snapToTileWidth,
                          onChanged: (v) => setState(() => snapToTileWidth = v),
                        ),
                        DropdownButton<SnapAlign>(
                          value: snapAlign,
                          items: const [
                            DropdownMenuItem(value: SnapAlign.left, child: Text("Left")),
                            DropdownMenuItem(value: SnapAlign.center, child: Text("Center")),
                            DropdownMenuItem(value: SnapAlign.right, child: Text("Right")),
                          ],
                          onChanged: (v) => setState(() => snapAlign = v!),
                        ),
                        _slider(
                          "Grid Tile Width",
                          gridTileWidth,
                          100,
                          400,
                          (v) => setState(() => gridTileWidth = v),
                        ),
                        _stepper(
                          "Grid Min Columns",
                          gridMinColumns,
                          (v) => setState(() => gridMinColumns = v),
                        ),
                        _stepper(
                          "Grid Max Columns",
                          gridMaxColumns,
                          (v) => setState(() => gridMaxColumns = v),
                        ),
                        _nullableSlider(
                          "Grid Header Height",
                          gridHeaderHeight,
                          24,
                          120,
                          (v) => setState(() => gridHeaderHeight = v),
                        ),
                        _nullableSlider(
                          "Grid Body Height",
                          gridBodyHeight,
                          40,
                          200,
                          (v) => setState(() => gridBodyHeight = v),
                        ),
                        _nullableSlider(
                          "Grid Trailing Height",
                          gridTrailingHeight,
                          0,
                          80,
                          (v) => setState(() => gridTrailingHeight = v),
                        ),
                        _nullableSlider(
                          "Grid Section Gap",
                          gridSectionGap,
                          0,
                          40,
                          (v) => setState(() => gridSectionGap = v),
                        ),
                        _nullableSlider(
                          "Grid Tile Vertical Padding",
                          gridTileVerticalPadding,
                          0,
                          40,
                          (v) => setState(() => gridTileVerticalPadding = v),
                        ),
                        _slider(
                          "Grid Main Axis Spacing",
                          gridMainAxisSpacing,
                          0,
                          40,
                          (v) => setState(() => gridMainAxisSpacing = v),
                        ),
                        _slider(
                          "Grid Cross Axis Spacing",
                          gridCrossAxisSpacing,
                          0,
                          40,
                          (v) => setState(() => gridCrossAxisSpacing = v),
                        ),
                        _nullableSlider(
                          "List Tile Min Height",
                          listTileMinHeight,
                          40,
                          200,
                          (v) => setState(() => listTileMinHeight = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      ResponsiveEntitySliver<EntityDemo>(
                        items: items,
                        headerBuilder: (ctx, e) => placeholderImage,
                        bodyBuilder: (ctx, e) =>
                            EntityDescription(title: e.title, description: e.description),
                        trailingBuilder: (ctx, e) => const Icon(Icons.more_vert, size: 20),
                        onTap: (e) => debugPrint('Tapped ${e.title}'),
                        gridBreakpoint: gridBreakpoint,
                        snapToTileWidth: snapToTileWidth,
                        snapAlign: snapAlign,
                        gridTileWidth: gridTileWidth,
                        gridMinColumns: gridMinColumns,
                        gridMaxColumns: gridMaxColumns,
                        gridHeaderHeight: gridHeaderHeight,
                        // gridBodyHeight: gridBodyHeight,
                        gridSectionGap: gridSectionGap,
                        gridTileVerticalPadding: gridTileVerticalPadding,
                        gridPadding: gridPadding,
                        gridMainAxisSpacing: gridMainAxisSpacing,
                        gridCrossAxisSpacing: gridCrossAxisSpacing,
                        listTileMinHeight: listTileMinHeight,
                        listPadding: listPadding,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value.toStringAsFixed(0),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 50, child: Text(value.toStringAsFixed(0))),
      ],
    );
  }

  Widget _nullableSlider(
    String label,
    double? value,
    double min,
    double max,
    ValueChanged<double?> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        Expanded(
          child: Slider(
            value: (value ?? min),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            label: value?.toStringAsFixed(0) ?? "null",
            onChanged: (v) => onChanged(v),
          ),
        ),
        IconButton(icon: const Icon(Icons.clear), onPressed: () => onChanged(null)),
        SizedBox(width: 50, child: Text(value != null ? value.toStringAsFixed(0) : "null")),
      ],
    );
  }

  Widget _stepper(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 160, child: Text(label)),
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        Text(value.toString()),
        IconButton(icon: const Icon(Icons.add), onPressed: () => onChanged(value + 1)),
      ],
    );
  }
}
