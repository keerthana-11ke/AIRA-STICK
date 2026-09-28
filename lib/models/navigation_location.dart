import 'dart:convert';

class NavigationLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  NavigationLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  NavigationLocation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
  }) {
    return NavigationLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  factory NavigationLocation.fromJson(Map<String, dynamic> json) {
    return NavigationLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  static List<NavigationLocation> decodeList(String jsonText) {
    final List<dynamic> list = jsonDecode(jsonText) as List<dynamic>;
    return list
        .map(
          (item) => NavigationLocation.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  static String encodeList(List<NavigationLocation> locations) {
    final list = locations.map((item) => item.toJson()).toList();
    return jsonEncode(list);
  }
}
