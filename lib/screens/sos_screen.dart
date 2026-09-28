import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final isSos = provider.isSosActive;

    return Scaffold(
      appBar: AppBar(
        title: const Text("SOS EMERGENCY"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large emergency status widget
              if (isSos)
                _buildActiveSosBeacon(context)
              else
                _buildInactiveSosBeacon(context),

              const SizedBox(height: 24),

              // Location Tracking details Card
              _buildLocationCard(context, isSos),

              const SizedBox(height: 16),

              // Emergency contacts Card
              _buildEmergencyContactCard(context, provider),

              const SizedBox(height: 24),

              // Action buttons (Dismiss or Trigger)
              if (isSos)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A896),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    provider.dismissSos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Emergency state cleared. Standing down."),
                        backgroundColor: Color(0xFF00A896),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.gpp_good, color: Colors.white, size: 24),
                  label: const Text(
                    "Dismiss SOS / Mark Safe",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                )
              else
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD90429),
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    provider.triggerSos();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Emergency Beacon Triggered!"),
                        backgroundColor: Color(0xFFD90429),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.warning, color: Colors.white, size: 24),
                  label: const Text(
                    "Trigger Mock SOS Signal",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  // Active beacon container with glowing pulse
  Widget _buildActiveSosBeacon(BuildContext context) {
    return Card(
      color: const Color(0xFFFFE5E5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFD90429), width: 2),
      ),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20),
        child: Column(
          children: [
            // Pulsing Alarm circle
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD90429),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD90429).withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emergency_share,
                  color: Colors.white,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              "SOS BEACON ACTIVE",
              style: TextStyle(
                color: Color(0xFFD90429),
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Blind user pressed the physical SOS button on Aira stick. Initiating emergency procedures.",
              style: TextStyle(
                color: Color(0xFF5B0D18),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Inactive beacon state
  Widget _buildInactiveSosBeacon(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00A896).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.gpp_good_outlined,
                color: Color(0xFF00A896),
                size: 54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "System Secure",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No emergency events reported. The blind user is navigating normally.",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Visual simulated location card
  Widget _buildLocationCard(BuildContext context, bool isSos) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color beaconColor = isSos ? const Color(0xFFD90429) : const Color(0xFF5C2219);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: beaconColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "GPS Tracking Node",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isSos)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD90429).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      "TRACKING LIVE",
                      style: TextStyle(
                        color: Color(0xFFD90429),
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock Location values
            Row(
              children: [
                Expanded(
                  child: _buildLocationCoordinate(
                    context, 
                    "Latitude", 
                    isSos ? "12.9716° N" : "12.9715° N",
                  ),
                ),
                Container(width: 1, height: 35, color: isDark ? Colors.white12 : Colors.grey[200]),
                Expanded(
                  child: _buildLocationCoordinate(
                    context, 
                    "Longitude", 
                    isSos ? "77.5946° E" : "77.5945° E",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  Icons.my_location,
                  size: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Address: MG Road Sector-4, Bangalore, India",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Mock Visual map screen container
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark ? Colors.black26 : Colors.blueGrey.shade50,
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vector grids simulating maps
                  Opacity(
                    opacity: 0.15,
                    child: CustomPaint(
                      painter: MapGridPainter(),
                      size: const Size(double.infinity, 120),
                    ),
                  ),
                  // Centered Beacon pin
                  Icon(
                    Icons.location_on, 
                    size: 32, 
                    color: beaconColor,
                  ),
                  if (isSos)
                    // Visual sonar wave pulse ring
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFD90429).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Satellite Link Active",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildLocationCoordinate(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Emergency contact details card
  Widget _buildEmergencyContactCard(BuildContext context, NavigationProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.contact_phone_rounded,
                color: Colors.orange,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "EMERGENCY CARETAKER CONTACT",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    provider.emergencyContact,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Contact Buttons
            IconButton(
              icon: const Icon(Icons.call, color: Color(0xFF5C2219)),
              tooltip: "Mock Call",
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Simulating outgoing call to ${provider.emergencyContact}..."),
                    behavior: SnackBarBehavior.floating,
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

// Background map paint layout simulation
class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueGrey
      ..strokeWidth = 1.0;

    // Drawing roads/path segments
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.45, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.6, size.height), paint);
    
    // Circle intersections
    canvas.drawCircle(Offset(size.width * 0.38, size.height * 0.47), 16, paint..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
