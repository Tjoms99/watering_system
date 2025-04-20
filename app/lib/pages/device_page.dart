import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bleService = context.watch<BleService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Device'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          if (bleService.isScanning)
            LinearProgressIndicator(
              backgroundColor: theme.colorScheme.surfaceVariant,
              color: theme.colorScheme.primary,
            ),
          Expanded(
            child: bleService.discoveredDevices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning for devices...',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure your watering device is turned on',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: bleService.discoveredDevices.length,
                    itemBuilder: (context, index) {
                      final device = bleService.discoveredDevices[index];
                      return ListTile(
                        leading: Icon(
                          Icons.water_drop,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(device.name),
                        subtitle: Text(device.id),
                        trailing: IconButton(
                          icon: const Icon(Icons.bluetooth),
                          onPressed: () async {
                            await bleService.connectToDevice(device);
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FilledButton.icon(
              onPressed: bleService.isScanning
                  ? bleService.stopScan
                  : bleService.startScan,
              icon: Icon(
                bleService.isScanning ? Icons.stop : Icons.search,
              ),
              label: Text(
                bleService.isScanning ? 'Stop Scan' : 'Scan for Devices',
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
