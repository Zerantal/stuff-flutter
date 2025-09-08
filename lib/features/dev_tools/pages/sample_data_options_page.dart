// lib/features/dev_tools/pages/sample_data_options_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../services/contracts/data_service_interface.dart';
import '../../../services/contracts/image_data_service_interface.dart';
import '../../../services/utils/sample_data_populator.dart';

class SampleDataOptionsPage extends StatefulWidget {
  const SampleDataOptionsPage({super.key});

  @override
  State<SampleDataOptionsPage> createState() => _SampleDataOptionsPageState();
}

class _SampleDataOptionsPageState extends State<SampleDataOptionsPage> {
  final _form = GlobalKey<FormState>();

  // Defaults match SampleOptions()
  bool _clearExisting = true;
  bool _clearImages = true;
  bool _includeBase = true;
  String _seedText = ''; // blank => time-based seed

  int _extraTop = 1;
  int _extraChildPerTop = 1;
  int _extraItemsRoom = 2;
  int _extraItemsPerContainer = 2;

  double _containerImageChance = 0.85;
  double _itemImageChance = 0.65;

  bool _busy = false;

  int? _parseSeed(String s) {
    if (s.trim().isEmpty) return null;
    return int.tryParse(s.trim());
  }

  SampleOptions _toOptions() {
    return SampleOptions(
      clearExistingData: _clearExisting,
      clearImages: _clearImages,
      includeBaseSeeds: _includeBase,
      randomSeed: _parseSeed(_seedText),
      extraTopLevelContainersPerRoom: _extraTop,
      extraChildContainersPerTopLevel: _extraChildPerTop,
      extraItemsPerRoom: _extraItemsRoom,
      extraItemsPerContainer: _extraItemsPerContainer,
      containerImageChance: _containerImageChance,
      itemImageChance: _itemImageChance,
    );
  }

  Future<void> _runPopulate() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final data = context.read<IDataService>();
      IImageDataService? images;
      try {
        images = context.read<IImageDataService>();
      } catch (_) {
        images = null; // acceptable; populator works without images
      }

      final pop = SampleDataPopulator(
        dataService: data,
        imageDataService: images,
        options: _toOptions(),
      );
      await pop.populate();

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Random data loaded')));
      StatefulNavigationShell.of(context).goBranch(0);
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Populate failed')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('SampleDataOptionsPage'),
      appBar: AppBar(title: const Text('Random Data Options')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Reset options',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _clearExisting,
              onChanged: (v) => setState(() => _clearExisting = v),
              title: const Text('Clear existing data'),
              subtitle: const Text('Empties DB before seeding'),
            ),
            SwitchListTile(
              value: _clearImages,
              onChanged: (v) => setState(() => _clearImages = v),
              title: const Text('Clear stored images'),
              subtitle: const Text('If image service is available'),
            ),
            SwitchListTile(
              value: _includeBase,
              onChanged: (v) => setState(() => _includeBase = v),
              title: const Text('Include base seeds'),
              subtitle: const Text('Predefined locations/rooms + a few entities'),
            ),
            const Divider(height: 24),

            Text(
              'Randomization',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Random seed (optional)',
                hintText: 'Leave blank for time-based',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => _seedText = v,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return int.tryParse(v.trim()) != null ? null : 'Enter an integer';
              },
            ),
            const SizedBox(height: 16),

            _IntField(
              label: 'Extra top-level containers per room',
              value: _extraTop,
              onChanged: (v) => setState(() => _extraTop = v),
            ),
            _IntField(
              label: 'Extra child containers per top-level',
              value: _extraChildPerTop,
              onChanged: (v) => setState(() => _extraChildPerTop = v),
            ),
            _IntField(
              label: 'Extra items per room',
              value: _extraItemsRoom,
              onChanged: (v) => setState(() => _extraItemsRoom = v),
            ),
            _IntField(
              label: 'Extra items per container',
              value: _extraItemsPerContainer,
              onChanged: (v) => setState(() => _extraItemsPerContainer = v),
            ),
            const SizedBox(height: 16),

            const Text('Image attachment probabilities'),
            const SizedBox(height: 8),
            _SliderField(
              label: 'Containers',
              value: _containerImageChance,
              onChanged: (v) => setState(() => _containerImageChance = v),
            ),
            _SliderField(
              label: 'Items',
              value: _itemImageChance,
              onChanged: (v) => setState(() => _itemImageChance = v),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _busy ? null : _runPopulate,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_fix_high_outlined),
              label: const Text('Reset with Random Data'),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntField extends StatelessWidget {
  const _IntField({required this.label, required this.value, required this.onChanged});
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: value.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        keyboardType: TextInputType.number,
        validator: (v) {
          final n = int.tryParse((v ?? '').trim());
          if (n == null || n < 0) return 'Enter a non-negative integer';
          return null;
        },
        onChanged: (v) {
          final n = int.tryParse(v.trim());
          if (n != null && n >= 0) onChanged(n);
        },
      ),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({required this.label, required this.value, required this.onChanged});
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            min: 0,
            max: 1,
            divisions: 20,
            label: value.toStringAsFixed(2),
            onChanged: onChanged,
          ),
        ),
        SizedBox(width: 48, child: Text(value.toStringAsFixed(2), textAlign: TextAlign.end)),
      ],
    );
  }
}
