import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../models/plant_state.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late PlantMode _selectedMode;
  late int _intervalMinutes;
  late int _amountMl;

  @override
  void initState() {
    super.initState();
    final bleService = context.read<BleService>();
    _selectedMode = bleService.state.mode;
    _intervalMinutes = bleService.state.intervalMinutes;
    _amountMl = bleService.state.amountMl;
  }

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Watering Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<PlantMode>(
                      segments: const [
                        ButtonSegment<PlantMode>(
                          value: PlantMode.off,
                          label: Text('Off'),
                          icon: Icon(Icons.power_off),
                        ),
                        ButtonSegment<PlantMode>(
                          value: PlantMode.manual,
                          label: Text('Manual'),
                          icon: Icon(Icons.touch_app),
                        ),
                        ButtonSegment<PlantMode>(
                          value: PlantMode.scheduled,
                          label: Text('Scheduled'),
                          icon: Icon(Icons.schedule),
                        ),
                      ],
                      selected: {_selectedMode},
                      onSelectionChanged: (modes) {
                        setState(() {
                          _selectedMode = modes.first;
                        });
                        bleService.setMode(_selectedMode);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Watering Schedule',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: const Text('Interval'),
                      subtitle: Text('$_intervalMinutes minutes'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _intervalMinutes > 1
                                ? () {
                                    setState(() {
                                      _intervalMinutes--;
                                    });
                                    bleService.setInterval(_intervalMinutes);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              setState(() {
                                _intervalMinutes++;
                              });
                              bleService.setInterval(_intervalMinutes);
                            },
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Amount'),
                      subtitle: Text('$_amountMl ml'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: _amountMl > 10
                                ? () {
                                    setState(() {
                                      _amountMl -= 10;
                                    });
                                    bleService.setAmount(_amountMl);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: _amountMl < 250
                                ? () {
                                    setState(() {
                                      _amountMl += 10;
                                    });
                                    bleService.setAmount(_amountMl);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
