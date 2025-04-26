import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:provider/provider.dart';
import 'models/plant_state.dart';
import 'services/ble_service.dart';
import 'pages/device_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => BleService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plant Watering System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Watering System'),
        actions: [
          IconButton(
            icon: Icon(
              bleService.isConnected
                  ? Icons.bluetooth_connected
                  : Icons.bluetooth,
              color: bleService.isConnected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DevicePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (bleService.isConnected) {
            await bleService.readInitialState();
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!bleService.isConnected)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Icon(Icons.bluetooth_disabled, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Not Connected',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the Bluetooth icon to connect to a device',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: bleService.isWatering
                                      ? theme.colorScheme.primaryContainer
                                      : theme.colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  bleService.isWatering
                                      ? Icons.water_drop
                                      : Icons.water_drop_outlined,
                                  color: bleService.isWatering
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bleService.isWatering ? 'Watering' : 'Idle',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Plant is ${bleService.isWatering ? 'being watered' : 'resting'}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildInfoTile(
                            context,
                            icon: Icons.timer,
                            title: 'Last watered',
                            subtitle:
                                _formatDuration(bleService.lastWateredSeconds),
                          ),
                          _buildInfoTile(
                            context,
                            icon: Icons.settings,
                            title: 'Mode',
                            subtitle: _formatMode(bleService.state.mode),
                          ),
                          if (bleService.state.mode == PlantMode.scheduled)
                            _buildInfoTile(
                              context,
                              icon: Icons.schedule,
                              title: 'Next watering',
                              subtitle: bleService.state.nextWateringTime,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Mode Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Watering Mode',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 48, // Standard height for Material buttons
                            width: double.infinity,
                            child: SegmentedButton<PlantMode>(
                              segments: const [
                                ButtonSegment<PlantMode>(
                                  value: PlantMode.off,
                                  label: Text('Off'),
                                  icon: Icon(Icons.power_settings_new),
                                ),
                                ButtonSegment<PlantMode>(
                                  value: PlantMode.manual,
                                  label: Text('Tap'),
                                  icon: Icon(Icons.touch_app),
                                ),
                                ButtonSegment<PlantMode>(
                                  value: PlantMode.scheduled,
                                  label: Text('Auto'),
                                  icon: Icon(Icons.schedule),
                                ),
                              ],
                              selected: {bleService.state.mode},
                              onSelectionChanged: (modes) {
                                if (modes.isNotEmpty) {
                                  bleService.setMode(modes.first);
                                }
                              },
                            ),
                          ),
                          if (bleService.state.mode == PlantMode.manual) ...[
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: bleService.isWatering
                                  ? null
                                  : () => bleService.triggerWatering(),
                              icon: const Icon(Icons.water_drop),
                              label: Text(
                                bleService.isWatering
                                    ? 'Watering in progress...'
                                    : 'Water Now',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Settings Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Settings',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildSliderTile(
                            context,
                            icon: Icons.timer,
                            title: 'Watering Interval',
                            subtitle: _formatInterval(
                                bleService.state.intervalMinutes),
                            value: bleService.state.intervalMinutes.toDouble(),
                            min: 1,
                            max: 4320, // 3 days
                            divisions: 143, // 1 hour steps
                            onChanged: (value) {
                              bleService.setInterval(value.toInt());
                            },
                          ),
                          _buildSliderTile(
                            context,
                            icon: Icons.water_drop,
                            title: 'Water Amount',
                            subtitle: '${bleService.state.amountMl} ml',
                            value: bleService.state.amountMl.toDouble(),
                            min:
                                25, // Start at 25ml (most accurate measurement)
                            max: 275, // Up to 250ml
                            divisions: 50, // 5ml steps
                            onChanged: (value) {
                              bleService.setAmount(value.toInt());
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return _SliderTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      initialValue: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }
}

class _SliderTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double initialValue;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  const _SliderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void didUpdateWidget(_SliderTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  String _formatValue(double value) {
    if (widget.title == 'Watering Interval') {
      return _formatInterval(value.toInt());
    } else {
      return '${value.round()} ml';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.icon,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Slider(
            value: _value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            label: _formatValue(_value),
            onChanged: (newValue) {
              setState(() {
                _value = newValue;
              });
            },
            onChangeEnd: widget.onChanged,
          ),
        ],
      ),
    );
  }
}

String _formatDuration(int seconds) {
  if (seconds == 0) return 'Now';
  final duration = Duration(seconds: seconds);
  if (duration.inDays > 0) {
    return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''} ago';
  } else if (duration.inHours > 0) {
    final remainingMinutes = duration.inMinutes % 60;
    return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''} ${remainingMinutes > 0 ? 'and $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}' : ''} ago';
  } else if (duration.inMinutes > 0) {
    final remainingSeconds = duration.inSeconds % 60;
    return '${duration.inMinutes} minute${duration.inMinutes > 1 ? 's' : ''} ${remainingSeconds > 0 ? 'and $remainingSeconds second${remainingSeconds > 1 ? 's' : ''}' : ''} ago';
  } else {
    return '${duration.inSeconds} second${duration.inSeconds > 1 ? 's' : ''} ago';
  }
}

String _formatMode(PlantMode mode) {
  switch (mode) {
    case PlantMode.off:
      return 'Off';
    case PlantMode.manual:
      return 'Manual';
    case PlantMode.scheduled:
      return 'Scheduled';
  }
}

String _formatInterval(int minutes) {
  if (minutes < 60) {
    return '$minutes minute${minutes > 1 ? 's' : ''}';
  } else if (minutes < 1440) {
    // Less than 24 hours
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (remainingMinutes == 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    }
    return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes minute${remainingMinutes > 1 ? 's' : ''}';
  } else {
    final days = minutes ~/ 1440;
    final remainingHours = (minutes % 1440) ~/ 60;
    if (remainingHours == 0) {
      return '$days day${days > 1 ? 's' : ''}';
    }
    return '$days day${days > 1 ? 's' : ''} $remainingHours hour${remainingHours > 1 ? 's' : ''}';
  }
}

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final bleService = context.watch<BleService>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (bleService.isScanning)
            LinearProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          if (bleService.isConnected)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.bluetooth_connected,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connected to Device',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () async {
                        await bleService.disconnect();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.bluetooth_disabled),
                      label: const Text('Disconnect'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: bleService.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 48,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No devices found',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your device is turned on',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bleService.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = bleService.discoveredDevices[index];
                      return ListTile(
                        leading: const Icon(Icons.bluetooth),
                        title: Text(device.name),
                        subtitle: Text(device.id),
                        trailing: FilledButton(
                          onPressed: () async {
                            await bleService.connectToDevice(device);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text('Connect'),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: bleService.isScanning
                  ? () => bleService.stopScan()
                  : () => bleService.startScan(),
              icon: Icon(
                bleService.isScanning ? Icons.stop : Icons.search,
              ),
              label: Text(
                bleService.isScanning ? 'Stop Scanning' : 'Start Scanning',
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
