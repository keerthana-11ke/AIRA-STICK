import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'dart:math';

class RouteStep {
  final String instruction;
  final String command; // 'STRAIGHT', 'TURN_LEFT', 'TURN_RIGHT', 'ARRIVED'
  final double latitude;
  final double longitude;
  final double distance; // in meters

  RouteStep({
    required this.instruction,
    required this.command,
    required this.latitude,
    required this.longitude,
    required this.distance,
  });
}

class RoutingService {
  static Future<List<RouteStep>?> fetchRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required String destinationName,
  }) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/$startLon,$startLat;$endLon,$endLat?steps=true&geometries=geojson',
    );

    try {
      developer.log('[RoutingService] Fetching road route: $url', name: 'Routing');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        developer.log('[RoutingService] OSRM status failed: ${response.statusCode}', name: 'Routing');
        return null;
      }

      final data = json.decode(response.body);
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        developer.log('[RoutingService] Empty routes from OSRM', name: 'Routing');
        return null;
      }

      final route = routes.first;
      final legs = route['legs'] as List?;
      if (legs == null || legs.isEmpty) return null;

      final steps = legs.first['steps'] as List?;
      if (steps == null || steps.isEmpty) return null;

      final List<RouteStep> result = [];
      for (final step in steps) {
        final maneuver = step['maneuver'];
        final String modifier = maneuver['modifier'] ?? '';
        final String type = maneuver['type'] ?? '';
        final double distance = (step['distance'] as num).toDouble();
        final name = step['name'] ?? '';

        final locationList = maneuver['location'] as List;
        final double lon = (locationList[0] as num).toDouble();
        final double lat = (locationList[1] as num).toDouble();

        String command = 'STRAIGHT';
        String instruction = 'Go straight';

        if (type == 'arrive') {
          command = 'ARRIVED';
          instruction = 'You have arrived at $destinationName';
        } else if (modifier.contains('left')) {
          command = 'TURN_LEFT';
          instruction = 'Turn left';
          if (distance > 5) {
            instruction += ' in ${distance.toStringAsFixed(0)} meters';
          }
        } else if (modifier.contains('right')) {
          command = 'TURN_RIGHT';
          instruction = 'Turn right';
          if (distance > 5) {
            instruction += ' in ${distance.toStringAsFixed(0)} meters';
          }
        } else {
          command = 'STRAIGHT';
          instruction = 'Go straight';
          if (name.toString().isNotEmpty) {
            instruction += ' onto $name';
          }
        }

        result.add(RouteStep(
          instruction: instruction,
          command: command,
          latitude: lat,
          longitude: lon,
          distance: distance,
        ));
      }

      return result;
    } catch (e) {
      developer.log('[RoutingService] Fetching failed with error: $e', name: 'Routing');
      return null;
    }
  }

  /// Generates a local fallback calculated route in case the web API is offline.
  /// This creates a realistic zig-zag path and turn instructions to guide the user.
  static List<RouteStep> generateLocalCalculatedRoute({
    required double startLat,
    required double startLon,
    required double endLat,
    required double endLon,
    required String destinationName,
  }) {
    // We interpolate a zig-zag route to create a set of road-like maneuvers
    final p1 = Point(
      startLat + (endLat - startLat) * 0.3,
      startLon + (endLon - startLon) * 0.3,
    );
    final p2 = Point(
      startLat + (endLat - startLat) * 0.6 - (endLon - startLon) * 0.05,
      startLon + (endLon - startLon) * 0.6 + (endLat - startLat) * 0.05,
    );
    final p3 = Point(
      startLat + (endLat - startLat) * 0.8,
      startLon + (endLon - startLon) * 0.8,
    );

    return [
      RouteStep(
        instruction: 'Go straight',
        command: 'STRAIGHT',
        latitude: startLat,
        longitude: startLon,
        distance: 40.0,
      ),
      RouteStep(
        instruction: 'Turn left',
        command: 'TURN_LEFT',
        latitude: p1.x,
        longitude: p1.y,
        distance: 60.0,
      ),
      RouteStep(
        instruction: 'Turn right',
        command: 'TURN_RIGHT',
        latitude: p2.x,
        longitude: p2.y,
        distance: 50.0,
      ),
      RouteStep(
        instruction: 'Keep left',
        command: 'STRAIGHT',
        latitude: p3.x,
        longitude: p3.y,
        distance: 30.0,
      ),
      RouteStep(
        instruction: 'You have arrived at $destinationName',
        command: 'ARRIVED',
        latitude: endLat,
        longitude: endLon,
        distance: 0.0,
      ),
    ];
  }
}
