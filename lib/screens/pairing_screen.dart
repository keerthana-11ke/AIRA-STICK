import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/navigation_data.dart';
import 'home_screen.dart';

class PairingScreen extends StatefulWidget {
  final String guardianName;
  final String emergencyPhone;

  const PairingScreen({
    super.key,
    required this.guardianName,
    required this.emergencyPhone,
  });

  @override
  State<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends State<PairingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isScanning = true;
  bool _deviceDiscovered = false;
  bool _isPairing = false;
  bool _pairingSuccess = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    // Simulate scanning delay
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _deviceDiscovered = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handlePairDevice() {
    setState(() {
      _isPairing = true;
    });

    // Simulate link negotiation
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _pairingSuccess = true;
        });

        // Update provider with registered guardian name & phone number
        final provider = Provider.of<NavigationProvider>(context, listen: false);
        provider.updateEmergencyContact(widget.emergencyPhone);
        
        // Simulating auto-connecting the Bluetooth telemetry link upon successful first setup!
        if (!provider.hardwareInfo.isEsp32Connected) {
          provider.toggleBluetoothConnection();
        }

        // Delay success screen before navigating to dashboard
        Timer(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
              (route) => false,
            );
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("PAIR AIRA SMART STICK"),
        automaticallyImplyLeading: !_isPairing && !_pairingSuccess,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              // Step counter/header
              Text(
                "Final Step: Link Hardware Device".toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppTheme.secondaryBrick,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              
              if (_isScanning) ...[
                const Text(
                  "Scanning for nearby devices...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Ensure the AIRA Smart Stick is powered on and within Bluetooth range.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                // Pulsing Radar scan effect
                Center(
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryMahogany.withOpacity(0.05),
                          border: Border.all(
                            color: AppTheme.primaryMahogany.withOpacity(0.4 * _pulseController.value),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryMahogany.withOpacity(0.1),
                              border: Border.all(
                                color: AppTheme.primaryMahogany.withOpacity(0.6 * _pulseController.value),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.bluetooth_searching_rounded,
                                color: AppTheme.primaryMahogany,
                                size: 40,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Spacer(),
              ] else if (_deviceDiscovered && !_isPairing && !_pairingSuccess) ...[
                const Text(
                  "Smart Stick Discovered!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Tap the device below to establish a secure link.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 35),
                
                // Discovered Device Card
                Card(
                  margin: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.highlightApricot, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.highlightApricot.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.settings_input_antenna_rounded,
                            color: AppTheme.highlightApricot,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "AIRA Smart Stick",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                "MAC ID: 24:0A:C4:8B:58:AA",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.bluetooth_connected,
                          color: AppTheme.highlightApricot,
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _handlePairDevice,
                  child: const Text("Connect & Finish Setup"),
                ),
              ] else if (_isPairing) ...[
                const Text(
                  "Connecting to Smart Stick...",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Syncing security tokens and registering emergency caretaker parameters.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: AppTheme.highlightApricot,
                        strokeWidth: 4,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Writing SMS Routing Configs...",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ] else if (_pairingSuccess) ...[
                const Text(
                  "Link Successful!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Pairing negotiations complete. Opening your caretaker console.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary,
                  ),
                ),
                const Spacer(),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                      size: 60,
                    ),
                  ),
                ),
                const Spacer(),
              ],
              
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
