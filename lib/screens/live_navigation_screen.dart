import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/navigation_data.dart';
import '../services/location_service.dart';

class LiveNavigationScreen extends StatefulWidget {
  const LiveNavigationScreen({super.key});

  @override
  State<LiveNavigationScreen> createState() => _LiveNavigationScreenState();
}

class _LiveNavigationScreenState extends State<LiveNavigationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final telemetry = provider.telemetry;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("LIVE AiraGATOR"),
        actions: [
          IconButton(
            icon: Icon(
              telemetry.currentMode == "OUTDOOR"
                  ? Icons.forest
                  : Icons.home_work,
              color: const Color(0xFF00A896),
            ),
            tooltip: "Switch Mode",
            onPressed: () {
              provider.toggleMode();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Switched to ${telemetry.currentMode} Mode"),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Radar Screen Card
              _buildRadarCard(context, telemetry.detectedObjects),

              const SizedBox(height: 12),

              // Navigation Summary (Destination, GPS, Status, Instructions)
              _buildNavigationSummary(context, provider),

              const SizedBox(height: 16),

              // Active Obstacle Distance Sensors
              Row(
                children: [
                  Expanded(
                    child: _buildDistanceCard(
                      context: context,
                      title: "Front Distance",
                      value: telemetry.frontDistanceCm,
                      maxRange: 300,
                      unit: "cm",
                      color: telemetry.frontDistanceCm < 60
                          ? Colors.orange
                          : const Color(0xFF0F4C81),
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDistanceCard(
                      context: context,
                      title: "Pit Distance",
                      value: telemetry.pitDistanceCm,
                      maxRange: 200,
                      unit: "cm",
                      color: telemetry.pitDistanceCm < 100
                          ? Colors.orange
                          : const Color(0xFF00A896),
                      icon: Icons.south_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Telemetry Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildStatusGridCard(
                    context,
                    "Water Sensor",
                    telemetry.waterDetected ? "Water Detected" : "Not Detected",
                    telemetry.waterDetected
                        ? Colors.orange
                        : const Color(0xFF00A896),
                    telemetry.waterDetected
                        ? Icons.water_drop
                        : Icons.water_drop_outlined,
                  ),
                  _buildStatusGridCard(
                    context,
                    "Scene Complexity",
                    "Score: ${telemetry.sceneScore}/5",
                    const Color(0xFF0F4C81),
                    Icons.filter_hdr_outlined,
                  ),
                  _buildStatusGridCard(
                    context,
                    "Threat Speed",
                    telemetry.threatLevel == "CRITICAL"
                        ? "CRITICAL"
                        : (telemetry.frontDistanceCm < 60 ? "MEDIUM" : "LOW"),
                    telemetry.frontDistanceCm < 60
                        ? Colors.orange
                        : const Color(0xFF00A896),
                    Icons.speed,
                  ),
                  _buildStatusGridCard(
                    context,
                    "Animal Detection",
                    "None Detected",
                    const Color(0xFF00A896),
                    Icons.pets,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Spoken Audio Log Card
              _buildVoiceSpeakCard(context, telemetry.lastVoiceSpoken),

              const SizedBox(height: 16),

              // Object Feeds Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Detected Objects (YOLOv8)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5C2219).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${telemetry.detectedObjects.length} active",
                        style: const TextStyle(
                          color: Color(0xFF5C2219),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Detected Objects list
              if (telemetry.detectedObjects.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        "No objects detected in camera feed.",
                        style: TextStyle(
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                )
              else
                ...telemetry.detectedObjects.map(
                  (obj) => _buildObjectListItem(context, obj),
                ),

              const SizedBox(height: 80), // Padding for Bluetooth FAB
            ],
          ),
        ),
      ),
    );
  }

  // Radar Sweeper Visualizer Card
  Widget _buildRadarCard(BuildContext context, List<DetectedObject> objects) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.radar, color: Color(0xFF5C2219), size: 20),
                    SizedBox(width: 8),
                    Text(
                      "AI Context Sonar Map",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.lens, color: Colors.green, size: 8),
                      SizedBox(width: 4),
                      Text(
                        "LIVE",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Dynamic custom painter for Radar Sweep
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: RadarPainter(
                        animationValue: _radarController.value,
                        detectedObjects: objects,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRadarLegend("Left", const Color(0xFF5C2219)),
                _buildRadarLegend("Ahead", const Color(0xFFE58554)),
                _buildRadarLegend("Right", Colors.purpleAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarLegend(String direction, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          direction,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // Dynamic Distance Status Cards
  Widget _buildDistanceCard({
    required BuildContext context,
    required String title,
    required int value,
    required int maxRange,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final percent = (value / maxRange).clamp(0.0, 1.0);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "$value",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white10 : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small Grid Metric Tiles
  Widget _buildStatusGridCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Last Speaker Announcement log
  Widget _buildVoiceSpeakCard(BuildContext context, String spokenVoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF5C2219).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.record_voice_over,
                color: Color(0xFF5C2219),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ACOUSTIC READOUT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '"$spokenVoice"',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
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

  Widget _buildNavigationSummary(
    BuildContext context,
    NavigationProvider provider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Navigation',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  provider.navigationStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Destination: ${provider.activeDestination?.name ?? 'None'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Current GPS: ${provider.currentLatitude.toStringAsFixed(5)}, ${provider.currentLongitude.toStringAsFixed(5)}',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Current instruction: ${provider.currentInstruction.isNotEmpty ? provider.currentInstruction : '—'}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Next instruction: ${provider.nextInstruction.isNotEmpty ? provider.nextInstruction : '—'}',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  provider.distanceRemaining > 1000
                      ? 'Dist: ${(provider.distanceRemaining / 1000).toStringAsFixed(2)} km'
                      : 'Dist: ${provider.distanceRemaining.toStringAsFixed(0)} m',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  provider.timeRemaining > 60
                      ? 'Time: ${(provider.timeRemaining / 60).toStringAsFixed(0)} min ${(provider.timeRemaining % 60).toStringAsFixed(0)} sec'
                      : 'Time: ${provider.timeRemaining.toStringAsFixed(0)} sec',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (provider.navigationStatus == 'Navigating') ...[
              const SizedBox(height: 12),
              Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.black26 : Colors.blueGrey.shade50.withOpacity(0.5),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomPaint(
                    painter: RouteMapPainter(
                      routePoints: provider.routePoints,
                      currentLat: provider.currentLatitude,
                      currentLon: provider.currentLongitude,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Object list items with direction metadata
  Widget _buildObjectListItem(BuildContext context, DetectedObject obj) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color labelColor;
    IconData objIcon;
    switch (obj.label.toLowerCase()) {
      case "person":
        labelColor = const Color(0xFF5C2219);
        objIcon = Icons.person;
        break;
      case "bicycle":
        labelColor = Colors.purpleAccent;
        objIcon = Icons.directions_bike;
        break;
      default:
        labelColor = const Color(0xFFE58554);
        objIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF221A18) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.blueGrey.shade50,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(objIcon, color: labelColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                obj.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "Direction: ${obj.direction}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RouteMapPainter extends CustomPainter {
  final List<math.Point<double>> routePoints;
  final double currentLat;
  final double currentLon;

  RouteMapPainter({
    required this.routePoints,
    required this.currentLat,
    required this.currentLon,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (routePoints.isEmpty) return;

    // Find bounding box to scale coordinates to map size
    double minLat = routePoints.first.x;
    double maxLat = routePoints.first.x;
    double minLon = routePoints.first.y;
    double maxLon = routePoints.first.y;

    for (final p in routePoints) {
      if (p.x < minLat) minLat = p.x;
      if (p.x > maxLat) maxLat = p.x;
      if (p.y < minLon) minLon = p.y;
      if (p.y > maxLon) maxLon = p.y;
    }

    // Add padding
    final latRange = (maxLat - minLat).abs();
    final lonRange = (maxLon - minLon).abs();
    minLat -= latRange == 0 ? 0.001 : latRange * 0.15;
    maxLat += latRange == 0 ? 0.001 : latRange * 0.15;
    minLon -= lonRange == 0 ? 0.001 : lonRange * 0.15;
    maxLon += lonRange == 0 ? 0.001 : lonRange * 0.15;

    final double width = size.width;
    final double height = size.height;

    Offset toOffset(double lat, double lon) {
      final double x = width * 0.1 + width * 0.8 * ((lon - minLon) / (maxLon - minLon == 0 ? 1 : maxLon - minLon));
      // Invert Y coordinate since screen Y grows downwards
      final double y = height * 0.9 - height * 0.8 * ((lat - minLat) / (maxLat - minLat == 0 ? 1 : maxLat - minLat));
      return Offset(x, y);
    }

    // Draw route line
    final pathPaint = Paint()
      ..color = const Color(0xFF5C2219)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final startOffset = toOffset(routePoints.first.x, routePoints.first.y);
    path.moveTo(startOffset.dx, startOffset.dy);
    for (int i = 1; i < routePoints.length; i++) {
      final offset = toOffset(routePoints[i].x, routePoints[i].y);
      path.lineTo(offset.dx, offset.dy);
    }
    canvas.drawPath(path, pathPaint);

    // Draw waypoints
    final pointPaint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill;

    for (int i = 0; i < routePoints.length; i++) {
      final offset = toOffset(routePoints[i].x, routePoints[i].y);
      canvas.drawCircle(offset, 4.0, pointPaint);
    }

    // Draw destination pin
    final destOffset = toOffset(routePoints.last.x, routePoints.last.y);
    final destPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(destOffset, 8.0, destPaint);

    // Draw user current location dot
    final userOffset = toOffset(currentLat, currentLon);
    final userGlowPaint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(userOffset, 12.0, userGlowPaint);

    final userPaint = Paint()
      ..color = Colors.blue;
    canvas.drawCircle(userOffset, 6.0, userPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Radar sweep Custom Painter
class RadarPainter extends CustomPainter {
  final double animationValue;
  final List<DetectedObject> detectedObjects;
  final bool isDark;

  RadarPainter({
    required this.animationValue,
    required this.detectedObjects,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Background circle paint
    final bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius, bgPaint);

    // Radar concentric rings
    final ringPaint = Paint()
      ..color = isDark ? Colors.white12 : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, maxRadius, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.66, ringPaint);
    canvas.drawCircle(center, maxRadius * 0.33, ringPaint);

    // Crosshairs lines
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      ringPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      ringPaint,
    );

    // Radar Sweep sweep line
    final sweepPaint = Paint()
      ..color = const Color(0xFF5C2219).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final double sweepAngle = animationValue * 2 * math.pi;
    final double sweepWidth = math.pi / 4; // 45 degrees sweep shadow

    final path = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: maxRadius),
        sweepAngle - sweepWidth,
        sweepWidth,
        false,
      )
      ..close();
    canvas.drawPath(path, sweepPaint);

    // Draw sweep active line edge
    final linePaint = Paint()
      ..color = const Color(0xFF5C2219).withOpacity(0.7)
      ..strokeWidth = 2.0;
    canvas.drawLine(
      center,
      Offset(
        center.dx + maxRadius * math.cos(sweepAngle),
        center.dy + maxRadius * math.sin(sweepAngle),
      ),
      linePaint,
    );

    // Draw simulated detected objects on radar
    // We position objects dynamically in coordinate sectors
    for (int i = 0; i < detectedObjects.length; i++) {
      final obj = detectedObjects[i];
      double angle = 0.0;
      double distanceRatio = 0.5 + (i * 0.15); // mock distance

      if (obj.direction.toLowerCase() == "left") {
        angle = math.pi + (i * 0.2); // Left sector (around 180 degrees)
      } else if (obj.direction.toLowerCase() == "right") {
        angle = 0.0 - (i * 0.2); // Right sector (around 0 degrees)
      } else {
        angle = -math.pi / 2 + (i * 0.1); // Ahead sector (around 270 degrees)
      }

      final double x =
          center.dx + (maxRadius * distanceRatio) * math.cos(angle);
      final double y =
          center.dy + (maxRadius * distanceRatio) * math.sin(angle);

      // Pulse color based on item label
      final dotColor = obj.label.toLowerCase() == "person"
          ? const Color(0xFF5C2219)
          : (obj.label.toLowerCase() == "bicycle"
                ? Colors.purpleAccent
                : const Color(0xFFE58554));

      // Draw dot drop-shadow glow
      final glowPaint = Paint()
        ..color = dotColor.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 10.0, glowPaint);

      // Draw object center point dot
      final dotPaint = Paint()
        ..color = dotColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), 5.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
