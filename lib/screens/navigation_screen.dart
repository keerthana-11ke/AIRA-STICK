import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../models/navigation_data.dart';
import '../models/navigation_session.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final session = provider.buildNavigationSession();
    final commandLog = provider.navigationInstructions.isEmpty
        ? const ['DESTINATION_SELECTED (mock)']
        : [
            'DESTINATION_SELECTED',
            ...provider.navigationInstructions.map((instruction) {
              final normalized = instruction.toLowerCase();
              if (normalized.contains('left')) return 'TURN_LEFT';
              if (normalized.contains('right')) return 'TURN_RIGHT';
              if (normalized.contains('straight')) return 'STRAIGHT';
              if (normalized.contains('reached')) return 'ARRIVED';
              return 'STRAIGHT';
            }),
          ];

    return Scaffold(
      appBar: AppBar(title: const Text('Navigation')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Destination:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        session.destinationName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance remaining:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.distanceRemaining > 1000
                                    ? '${(provider.distanceRemaining / 1000).toStringAsFixed(2)} km'
                                    : '${provider.distanceRemaining.toStringAsFixed(0)} m',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Est. time remaining:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.timeRemaining > 60
                                    ? '${(provider.timeRemaining / 60).toStringAsFixed(0)} min ${(provider.timeRemaining % 60).toStringAsFixed(0)} sec'
                                    : '${provider.timeRemaining.toStringAsFixed(0)} sec',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Route Map:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.blueGrey.shade50.withOpacity(0.5),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CustomPaint(
                            painter: RouteMapPainter(
                              routePoints: provider.routePoints,
                              currentLat: provider.currentLatitude,
                              currentLon: provider.currentLongitude,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5C2219).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF5C2219).withOpacity(0.3)),
                        ),
                        child: Text(
                          'Status: ${session.navigationStatus}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE58554),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'CURRENT INSTRUCTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Color(0xFFE58554),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.currentInstruction.isNotEmpty
                            ? session.currentInstruction
                            : '—',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'NEXT INSTRUCTION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.nextInstruction.isNotEmpty
                            ? session.nextInstruction
                            : '—',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: provider.navigationStatus == 'Navigating'
                            ? () async {
                                provider.stopNavigation();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Navigation stopped'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD90429),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                        ),
                        child: const Text(
                          'STOP NAVIGATION',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
