import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';
import '../models/navigation_location.dart';
import '../services/ble_service.dart';
import 'device_info_screen.dart';
import 'onboarding_screen.dart';
import 'bluetooth_devices_screen.dart';
import 'navigation_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final telemetry = provider.telemetry;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bleIsConnected = BleService.instance.isConnected;

    // Formatting the Last Updated time
    final lastUpdatedStr =
        "${telemetry.lastUpdated.hour.toString().padLeft(2, '0')}:${telemetry.lastUpdated.minute.toString().padLeft(2, '0')}:${telemetry.lastUpdated.second.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("AIRA"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Device Details",
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DeviceInfoScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome, Guardian",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: bleIsConnected
                                    ? const Color(0xFF5C2219)
                                    : Colors.red,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              bleIsConnected
                                  ? "Smart Stick Connected"
                                  : "Smart Stick Disconnected",
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Quick profile avatar representing Caretaker
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFF5C2219).withOpacity(0.1),
                      child: const Icon(
                        Icons.account_circle,
                        size: 40,
                        color: Color(0xFF5C2219),
                      ),
                    ),
                  ],
                ),
              ),

              // Bluetooth Connection Call-to-Action (if not connected)
              if (!bleIsConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C2219).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF5C2219).withOpacity(0.3),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const BluetoothDevicesScreen(),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                color: const Color(0xFF5C2219),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Connect Smart Stick',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to pair AIRA-STICK device',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_rounded,
                                color: const Color(0xFF5C2219),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Bluetooth Connected Badge (if connected)
              if (bleIsConnected)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C2219).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF5C2219)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.bluetooth_connected,
                            color: const Color(0xFF5C2219),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Smart Stick Connected',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  BleService.instance.statusMessage,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              _buildQuickGuideCard(context),

              const SizedBox(height: 12),

              // Threat Level Badge (Critical environmental status banner)
              _buildThreatBanner(context, telemetry.threatLevel),

              const SizedBox(height: 8),

              // Saved Locations Card
              _buildSavedLocationsCard(context, provider),

              const SizedBox(height: 8),

              // Grid for Status Cards
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.05,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  // Battery Card
                  _buildBatteryCard(
                    context,
                    telemetry.batteryPercent,
                    telemetry.isCharging,
                  ),

                  // Navigation Mode Card
                  _buildModeCard(context, telemetry.currentMode, provider),

                  // Alert Status Card
                  _buildAlertStatusCard(context, provider),

                  // Connection Strength Card
                  _buildConnectionCard(context, provider, lastUpdatedStr),
                ],
              ),

              const SizedBox(height: 16),

              // Smart Stick Summary Card (compact, non-intrusive)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSmartStickCard(context, provider),
              ),

              const SizedBox(height: 12),

              // Live Obstacle Overview summary card
              _buildQuickTelemetrySummary(context, telemetry),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Large Threat Level Banner
  Widget _buildThreatBanner(BuildContext context, String level) {
    Color bannerColor;
    Color textColor;
    IconData icon;
    String description;

    switch (level) {
      case "CRITICAL":
        bannerColor = const Color(0xFFFFE5E5);
        textColor = const Color(0xFFD90429);
        icon = Icons.gpp_maybe_rounded;
        description = "CRITICAL THREAT: Emergency Active!";
        break;
      case "HIGH":
        bannerColor = const Color(0xFFFFF2E5);
        textColor = const Color(0xFFE85D04);
        icon = Icons.warning_amber_rounded;
        description = "HIGH THREAT: Immediate Danger Detected";
        break;
      case "MEDIUM":
        bannerColor = const Color(0xFFFFFBE5);
        textColor = const Color(0xFFF7B500);
        icon = Icons.info_outline;
        description = "MODERATE RISK: Caution Advised";
        break;
      case "LOW":
      default:
        bannerColor = const Color(0xFFB3574A).withOpacity(0.25);
        textColor = const Color(0xFF5C2219);
        icon = Icons.gpp_good_rounded;
        description = "LOW RISK: Environment is Clear";
        break;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // In dark mode, use deep color fills instead of bright white pastels
    final fillBgColor = isDark ? textColor.withOpacity(0.15) : bannerColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fillBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: textColor.withOpacity(isDark ? 0.3 : 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ENVIRONMENTAL THREAT LEVEL",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: isDark
                        ? Colors.grey[300]
                        : textColor.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : textColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: textColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              level,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Battery Status Card
  Widget _buildBatteryCard(
    BuildContext context,
    int percentage,
    bool isCharging,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color batteryColor;
    if (percentage > 50) {
      batteryColor = const Color(0xFF5C2219);
    } else if (percentage > 20) {
      batteryColor = Colors.orange;
    } else {
      batteryColor = const Color(0xFFD90429);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Battery Info",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Icon(
                  isCharging ? Icons.battery_charging_full : Icons.battery_std,
                  color: batteryColor,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 64,
                    width: 64,
                    child: CircularProgressIndicator(
                      value: percentage / 100.0,
                      strokeWidth: 6,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(batteryColor),
                    ),
                  ),
                  Text(
                    "$percentage%",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                isCharging ? "Charging Mode" : "Battery Health: Good",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Active Mode Card
  Widget _buildModeCard(
    BuildContext context,
    String mode,
    NavigationProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOutdoor = mode == "OUTDOOR";

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          provider.toggleMode();
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "System Mode",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  Icon(
                    isOutdoor ? Icons.forest : Icons.home_work,
                    color: const Color(0xFF5C2219),
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C2219).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isOutdoor ? Icons.navigation_rounded : Icons.radar,
                    size: 32,
                    color: const Color(0xFF5C2219),
                  ),
                ),
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    Text(
                      mode,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Tap to switch mode",
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Alert Status Card
  Widget _buildAlertStatusCard(
    BuildContext context,
    NavigationProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final telemetry = provider.telemetry;

    String alertText = "Path Clear";
    IconData alertIcon = Icons.check_circle_outline;
    Color alertColor = const Color(0xFF5C2219);

    if (provider.isSosActive) {
      alertText = "SOS ACTIVE";
      alertIcon = Icons.emergency;
      alertColor = const Color(0xFFD90429);
    } else if (telemetry.waterDetected) {
      alertText = "Water Alert";
      alertIcon = Icons.water_drop;
      alertColor = Colors.orange;
    } else if (telemetry.frontDistanceCm < 60) {
      alertText = "Obstacle Close";
      alertIcon = Icons.warning_amber_outlined;
      alertColor = Colors.orange;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Alert Status",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Icon(alertIcon, color: alertColor, size: 20),
              ],
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(alertIcon, size: 32, color: alertColor),
              ),
            ),
            const Spacer(),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: alertColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  alertText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: alertColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Stick Status / Bluetooth Connection Card
  Widget _buildConnectionCard(
    BuildContext context,
    NavigationProvider provider,
    String lastUpdatedStr,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = provider.hardwareInfo.isEsp32Connected;

    IconData signalIcon = Icons.bluetooth;
    if (!isConnected) {
      signalIcon = Icons.bluetooth_disabled;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Stick Signal",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Icon(
                  signalIcon,
                  color: isConnected ? const Color(0xFF5C2219) : Colors.grey,
                  size: 20,
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: Column(
                children: [
                  Text(
                    isConnected ? "CONNECTED" : "OFFLINE",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isConnected
                          ? const Color(0xFF5C2219)
                          : Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected
                        ? "RSSI: ${provider.hardwareInfo.signalStrengthDb} dBm"
                        : "Link Lost",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                "Updated: $lastUpdatedStr",
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact Smart Stick Status Card
  Widget _buildSmartStickCard(
    BuildContext context,
    NavigationProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hw = provider.hardwareInfo;
    final lastAlert = provider.alerts.isNotEmpty
        ? provider.alerts.first.title
        : 'No recent alerts';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Smart Stick",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                Icon(
                  hw.isEsp32Connected ? Icons.usb : Icons.usb_off,
                  color: hw.isEsp32Connected
                      ? const Color(0xFF5C2219)
                      : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection: ${hw.isEsp32Connected ? 'Connected' : 'Disconnected'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Battery: --',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Front Sensor: Ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Pit Sensor: Ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Water Sensor: Ready',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'DFPlayer: ${hw.dfPlayerStatus}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Icon(Icons.sticky_note_2, color: Color(0xFF5C2219)),
                      const SizedBox(height: 8),
                      Text(
                        'Last Alert',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastAlert,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Quick Telemetry Summary Card (Front obstacles, Voice Output, etc.)
  Widget _buildQuickTelemetrySummary(
    BuildContext context,
    NavigationTelemetry telemetry,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221A18) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.blueGrey.shade50,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volume_up, color: Color(0xFF5C2219), size: 20),
              const SizedBox(width: 8),
              Text(
                "Last Acoustic Announcement",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF5C2219).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF5C2219).withOpacity(0.1),
              ),
            ),
            child: Text(
              '"${telemetry.lastVoiceSpoken}"',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontStyle: FontStyle.italic,
                color: Color(0xFF5C2219),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                context,
                "Front Dist.",
                "${telemetry.frontDistanceCm} cm",
                Icons.arrow_forward_rounded,
                telemetry.frontDistanceCm < 60
                    ? Colors.orange
                    : const Color(0xFF5C2219),
              ),
              Container(
                width: 1,
                height: 35,
                color: isDark ? Colors.white10 : Colors.grey[200],
              ),
              _buildMetricItem(
                context,
                "Pit Dist.",
                "${telemetry.pitDistanceCm} cm",
                Icons.south_rounded,
                telemetry.pitDistanceCm < 100
                    ? Colors.orange
                    : const Color(0xFF5C2219),
              ),
              Container(
                width: 1,
                height: 35,
                color: isDark ? Colors.white10 : Colors.grey[200],
              ),
              _buildMetricItem(
                context,
                "Scene Score",
                "Score: ${telemetry.sceneScore}/5",
                Icons.analytics_rounded,
                const Color(0xFF5C2219),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildQuickGuideCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF221A18) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE58554).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lightbulb,
                color: Color(0xFFE58554),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "New to Aira Smart Stick?",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Learn pairing steps, audio controls & safety manual.",
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFFB8A29E)
                          : const Color(0xFF6E5651),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const OnboardingScreen(readOnly: true),
                  ),
                );
              },
              child: const Text(
                "Read Guide",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedLocationsCard(BuildContext context, NavigationProvider provider) {
    final locations = provider.savedLocations;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bleIsConnected = BleService.instance.isConnected;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF221A18) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.bookmarks_outlined,
                      color: Color(0xFF5C2219),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Saved Locations",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (!bleIsConnected)
                  const Text(
                    "Connect stick to navigate",
                    style: TextStyle(fontSize: 11, color: Colors.redAccent),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                final loc = locations[index];
                IconData locIcon = Icons.location_on;
                final nameLower = loc.name.toLowerCase();
                if (nameLower.contains('railway')) {
                  locIcon = Icons.directions_transit;
                } else if (nameLower.contains('library')) {
                  locIcon = Icons.local_library;
                } else if (nameLower.contains('hospital')) {
                  locIcon = Icons.local_hospital;
                }

                final isNavigatingThis = provider.activeDestination?.id == loc.id;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? const Color(0xFF2C2220) 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isNavigatingThis
                            ? const Color(0xFFE58554)
                            : (isDark ? const Color(0xFF3D2D2A) : Colors.grey[300]!),
                        width: isNavigatingThis ? 2.0 : 1.0,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: (!bleIsConnected || provider.isRouteLoading)
                            ? null
                            : () async {
                                try {
                                  await provider.selectLocationById(loc.id);
                                  
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Navigating to ${loc.name}...'),
                                        backgroundColor: const Color(0xFF5C2219),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );

                                    await Future.delayed(const Duration(milliseconds: 500));
                                    if (context.mounted) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => const NavigationScreen(),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to start navigation: $e'),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  }
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isNavigatingThis
                                      ? const Color(0xFFE58554).withOpacity(0.15)
                                      : const Color(0xFF5C2219).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  locIcon, 
                                  color: isNavigatingThis 
                                      ? const Color(0xFFE58554) 
                                      : const Color(0xFF5C2219),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      loc.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${loc.latitude.toStringAsFixed(5)}, Lng: ${loc.longitude.toStringAsFixed(5)}',
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isNavigatingThis)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE58554),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFE58554).withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    "Navigating",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: isDark ? const Color(0xFFE58554) : const Color(0xFF5C2219),
                                  size: 16,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
