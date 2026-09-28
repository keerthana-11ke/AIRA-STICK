import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';
import '../models/navigation_location.dart';
import '../services/smart_stick_service.dart';
import '../services/ble_service.dart';
import 'navigation_screen.dart';

class SavedLocationsScreen extends StatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  State<SavedLocationsScreen> createState() => _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends State<SavedLocationsScreen> {
  String? _lastCommandStatus;

  Future<void> _startNavigationToLocation(
    BuildContext context,
    NavigationLocation location,
  ) async {
    final provider = Provider.of<NavigationProvider>(context, listen: false);

    // Check if Bluetooth is connected
    if (!BleService.instance.isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Smart Stick not connected. Please connect first.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    try {
      // Select the location
      await provider.selectLocationById(location.id);

      setState(() {
        _lastCommandStatus = 'Navigation started: ${location.name}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigating to ${location.name}...'),
            backgroundColor: const Color(0xFF5C2219),
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate to the navigation screen
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const NavigationScreen()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _lastCommandStatus = 'Failed to start navigation';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start navigation: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final locations = provider.savedLocations;
    final bleIsConnected = BleService.instance.isConnected;

    return Scaffold(
      appBar: AppBar(title: const Text('Saved Locations')),
      body: SafeArea(
        child: Column(
          children: [
            // BLE Connection Status Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bleIsConnected
                    ? const Color(0xFF5C2219).withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                border: Border(
                  bottom: BorderSide(
                    color: bleIsConnected
                        ? const Color(0xFF5C2219)
                        : Colors.red,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    bleIsConnected
                        ? Icons.bluetooth_connected
                        : Icons.bluetooth_disabled,
                    color: bleIsConnected
                        ? const Color(0xFF5C2219)
                        : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bleIsConnected
                              ? 'Smart Stick Connected'
                              : 'Smart Stick Disconnected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: bleIsConnected
                                ? const Color(0xFF5C2219)
                                : Colors.red,
                          ),
                        ),
                        if (!bleIsConnected)
                          const Text(
                            'Connect first to send navigation commands',
                            style: TextStyle(fontSize: 11, color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: locations.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      itemCount: locations.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final location = locations[index];
                        final isSelected = provider.activeDestination?.id == location.id;

                        return Card(
                          margin: EdgeInsets.zero,
                          color: isSelected ? const Color(0xFF5C2219).withOpacity(0.08) : null,
                          shape: isSelected
                              ? RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: const BorderSide(color: Color(0xFF5C2219), width: 1.5),
                                )
                              : null,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            title: Text(
                              isSelected ? '${location.name} ✓' : location.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? const Color(0xFF5C2219) : null,
                              ),
                            ),
                            subtitle: Text(
                              'Lat: ${location.latitude.toStringAsFixed(5)}, Lon: ${location.longitude.toStringAsFixed(5)}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: provider.isRouteLoading && provider.activeDestination?.id == location.id
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5C2219)),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.directions,
                                          color: Color(0xFF5C2219),
                                        ),
                                  tooltip: 'Start Navigation',
                                  onPressed: provider.isRouteLoading
                                      ? null
                                      : () {
                                          _startNavigationToLocation(
                                            context,
                                            location,
                                          );
                                        },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Color(0xFF5C2219),
                                  ),
                                  onPressed: () => _showLocationEditor(
                                    context,
                                    provider,
                                    location: location,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () => _confirmDeleteLocation(
                                    context,
                                    provider,
                                    location,
                                  ),
                                ),
                              ],
                            ),
                            onTap: (bleIsConnected && !provider.isRouteLoading)
                                ? () async {
                                    await _startNavigationToLocation(
                                      context,
                                      location,
                                    );
                                  }
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocationEditor(context, provider),
        icon: const Icon(Icons.add_location),
        label: const Text('Add Location'),
        backgroundColor: const Color(0xFF5C2219),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.location_off, size: 72, color: Colors.grey),
            SizedBox(height: 20),
            Text(
              'No saved locations yet. Create one now to start navigation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showLocationEditor(
    BuildContext context,
    NavigationProvider provider, {
    NavigationLocation? location,
  }) async {
    final nameController = TextEditingController(text: location?.name ?? '');
    final latController = TextEditingController(
      text: location?.latitude.toString() ?? '',
    );
    final lonController = TextEditingController(
      text: location?.longitude.toString() ?? '',
    );
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(location == null ? 'Add Location' : 'Edit Location'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Location Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Enter a name'
                      : null,
                ),
                TextFormField(
                  controller: latController,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter latitude';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: lonController,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter longitude';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final name = nameController.text.trim();
                final latitude = double.parse(latController.text.trim());
                final longitude = double.parse(lonController.text.trim());
                final navigator = Navigator.of(context);
                if (location == null) {
                  await provider.addLocation(
                    NavigationLocation(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      name: name,
                      latitude: latitude,
                      longitude: longitude,
                    ),
                  );
                } else {
                  await provider.updateLocation(
                    location.copyWith(
                      name: name,
                      latitude: latitude,
                      longitude: longitude,
                    ),
                  );
                }
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C2219),
              ),
              child: Text(location == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteLocation(
    BuildContext context,
    NavigationProvider provider,
    NavigationLocation location,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Location'),
          content: Text('Remove "${location.name}" from saved destinations?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await provider.deleteLocation(location.id);
                navigator.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
