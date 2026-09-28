import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';
import '../services/ble_service.dart';
import '../services/smart_stick_service.dart';

class BluetoothDevicesScreen extends StatefulWidget {
  const BluetoothDevicesScreen({super.key});

  @override
  State<BluetoothDevicesScreen> createState() => _BluetoothDevicesScreenState();
}

class _BluetoothDevicesScreenState extends State<BluetoothDevicesScreen> {
  bool _isScanning = false;
  List<DiscoveredBleDevice> _devices = [];
  String? _selectedDeviceAddress;
  bool _isConnecting = false;
  String _statusMessage = 'Ready to scan for devices';

  @override
  void initState() {
    super.initState();
    _listenToBleState();

    if (BleService.instance.isConnected) {
      final connectedDev = BleService.instance.connectedDevice;
      if (connectedDev != null) {
        _statusMessage = 'AIRA-STICK Connected';
        _selectedDeviceAddress = connectedDev.remoteId.str;
        _devices = [
          DiscoveredBleDevice(
            name: connectedDev.platformName.isNotEmpty ? connectedDev.platformName : 'AIRA-STICK',
            address: connectedDev.remoteId.str,
            rssi: -55,
            device: connectedDev,
          )
        ];
      }
    }
  }

  void _listenToBleState() {
    BleService.instance.connectionState.listen((state) {
      if (mounted) {
        setState(() {
          _statusMessage = BleService.instance.statusMessage;
        });
      }
    });
  }

  Future<void> _scanForDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _statusMessage = 'Scanning for devices...';
      _devices = [];
      _selectedDeviceAddress = null;
    });

    try {
      final devices = await SmartStickService.instance.scanForDevices(
        timeout: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _devices = devices;
          _isScanning = false;
          _statusMessage = BleService.instance.statusMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _statusMessage = BleService.instance.statusMessage;
        });
      }
    }
  }

  Future<void> _connectToDevice(String deviceAddress) async {
    if (BleService.instance.isConnected && BleService.instance.connectedDevice?.remoteId.str == deviceAddress) {
      setState(() {
        _isConnecting = false;
        _statusMessage = 'AIRA-STICK Connected';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    setState(() {
      _isConnecting = true;
      _statusMessage = 'Connecting...';
    });

    try {
      final success = await SmartStickService.instance.connectToDevice(
        deviceAddress,
      );

      if (success) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _statusMessage = 'Connected to AIRA-STICK!';
          });

          // Show success and pop after 1 second
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _statusMessage = 'Connection failed. Try again.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _statusMessage = 'Connection error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Smart Stick'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status message
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF5C2219).withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bluetooth Status',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Scan button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _isScanning || _isConnecting
                    ? null
                    : _scanForDevices,
                icon: _isScanning
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : const Icon(Icons.bluetooth_searching),
                label: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: const Color(0xFF5C2219),
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Devices list
            Expanded(
              child: _devices.isEmpty
                  ? Center(
                      child: Text(
                        _isScanning
                            ? 'Scanning...\nMake sure AIRA-STICK is turned on'
                            : 'No devices found\nTap "Scan for Devices" to start',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _devices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final isSelected =
                            device.address == _selectedDeviceAddress;
                        final isAiraStick = device.name == 'AIRA-STICK';

                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: isSelected ? 4 : 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Icon(
                              Icons.bluetooth,
                              color: isAiraStick
                                  ? const Color(0xFF5C2219)
                                  : Colors.grey,
                            ),
                            title: Text(
                              device.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  device.address,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Signal: ${device.rssi} dBm',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                                if (isAiraStick)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF5C2219,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Smart Stick',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: const Color(0xFF5C2219),
                                            ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            selected: isSelected,
                            onTap: _isConnecting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedDeviceAddress = isSelected
                                          ? null
                                          : device.address;
                                    });
                                  },
                            trailing:
                                _isConnecting &&
                                    device.address == _selectedDeviceAddress
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  )
                                : isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Theme.of(context).primaryColor,
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),

            // Connect button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed:
                    (_selectedDeviceAddress == null ||
                        _isConnecting ||
                        _isScanning ||
                        (BleService.instance.isConnected && BleService.instance.connectedDevice?.remoteId.str == _selectedDeviceAddress))
                    ? null
                    : () => _connectToDevice(_selectedDeviceAddress!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: const Color(0xFF5C2219),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: Text(
                  _isConnecting
                      ? 'Connecting...'
                      : (BleService.instance.isConnected && BleService.instance.connectedDevice?.remoteId.str == _selectedDeviceAddress)
                          ? 'Connected'
                          : 'Connect to Device',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
