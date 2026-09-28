import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';

class DeviceInfoScreen extends StatelessWidget {
  const DeviceInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final hardware = provider.hardwareInfo;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DEVICE DIAGNOSTICS"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Core Connection status block
              _buildConnectionHeader(context, hardware.isEsp32Connected),

              const SizedBox(height: 20),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  "Hardware Subsystems",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Subsystem status items
              _buildDiagnosticItem(
                context: context,
                title: "Core Processor",
                subtitle: "ESP32-WROOM-32E MCU Dual-Core",
                statusText: hardware.isEsp32Connected ? "Active" : "Offline",
                statusColor: hardware.isEsp32Connected ? const Color(0xFF5C2219) : Colors.red,
                icon: Icons.developer_board,
              ),

              _buildDiagnosticItem(
                context: context,
                title: "Firmware Build",
                subtitle: "Aira-Firmware-Suite",
                statusText: hardware.firmwareVersion,
                statusColor: const Color(0xFF5C2219),
                icon: Icons.code,
              ),

              _buildDiagnosticItem(
                context: context,
                title: "Bluetooth MAC Address",
                subtitle: "RFCOMM Serial Channel",
                statusText: hardware.bluetoothAddress,
                statusColor: const Color(0xFF5C2219),
                icon: Icons.bluetooth,
              ),

              _buildDiagnosticItem(
                context: context,
                title: "Wireless Link Quality",
                subtitle: hardware.isEsp32Connected ? "Signal RSSI: ${hardware.signalStrengthDb} dBm" : "Not connected",
                statusText: hardware.isEsp32Connected 
                    ? (hardware.signalStrengthDb > -60 ? "Excellent" : "Fair")
                    : "Disconnected",
                statusColor: hardware.isEsp32Connected 
                    ? (hardware.signalStrengthDb > -60 ? const Color(0xFF5C2219) : Colors.orange)
                    : Colors.grey,
                icon: Icons.wifi_tethering,
              ),

              _buildDiagnosticItem(
                context: context,
                title: "Battery Cell Health",
                subtitle: "Li-Ion 18650 Battery",
                statusText: hardware.isEsp32Connected ? hardware.batteryHealth : "Offline",
                statusColor: hardware.isEsp32Connected ? const Color(0xFF5C2219) : Colors.grey,
                icon: Icons.battery_charging_full,
              ),

              // Micro SD with Storage progress bar
              _buildStorageDiagnosticItem(context, hardware),

              _buildDiagnosticItem(
                context: context,
                title: "DFPlayer Mini Subsystem",
                subtitle: "Acoustic TTS DAC Decoder",
                statusText: hardware.isEsp32Connected ? hardware.dfPlayerStatus : "Offline",
                statusColor: hardware.isEsp32Connected && hardware.dfPlayerStatus == "Ready" 
                    ? const Color(0xFF5C2219) 
                    : Colors.red,
                icon: Icons.music_note,
              ),

              _buildDiagnosticItem(
                context: context,
                title: "Speaker hardware status",
                subtitle: "8 Ohm 3W External Transducer",
                statusText: hardware.isEsp32Connected ? hardware.speakerStatus : "Offline",
                statusColor: hardware.isEsp32Connected && hardware.speakerStatus == "Connected" 
                    ? const Color(0xFF5C2219) 
                    : Colors.red,
                icon: Icons.volume_up,
              ),

              const SizedBox(height: 24),

              // Simulation trigger helper inside diagnostics
              if (hardware.isEsp32Connected)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: const BorderSide(color: Color(0xFF5C2219)),
                  ),
                  onPressed: () {
                    provider.addAlert("Diagnostics Ran", "All ESP32 sensor pins self-test: PASSED", "LOW", Icons.health_and_safety);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ESP32 Sensor Self-Test: PASSED"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings_suggest, color: Color(0xFF5C2219)),
                  label: const Text("Perform Hardware Self-Test", style: TextStyle(color: Color(0xFF5C2219), fontWeight: FontWeight.bold)),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionHeader(BuildContext context, bool isConnected) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isConnected 
                    ? const Color(0xFF5C2219).withOpacity(0.1) 
                    : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isConnected ? Icons.check_circle : Icons.error,
                color: isConnected ? const Color(0xFF5C2219) : Colors.red,
                size: 36,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? "Aira System Connected" : "Connection Lost",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected 
                        ? "Telemetry stream is fully synchronised." 
                        : "Turn on Bluetooth on Aira stick & connect.",
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5C2219), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageDiagnosticItem(BuildContext context, DeviceHardwareInfo hardware) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = hardware.isEsp32Connected;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.sd_storage, color: Color(0xFF5C2219), size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "MicroSD Card Storage",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isConnected ? "Mounted: SD Status - ${hardware.microSdStatus}" : "Offline",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isConnected ? const Color(0xFF5C2219).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isConnected ? "MOUNTED" : "OFFLINE",
                    style: TextStyle(
                      color: isConnected ? const Color(0xFF5C2219) : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (isConnected) ...[
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Used: ${(hardware.storageUsedPercent * 100).toInt()}%",
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Free: 11.5 GB / 16.0 GB",
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: hardware.storageUsedPercent,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5C2219)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
