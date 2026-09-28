class NavigationSession {
  final double currentLatitude;
  final double currentLongitude;
  final String destinationName;
  final double destinationLatitude;
  final double destinationLongitude;
  final String navigationStatus;
  final String currentInstruction;
  final String nextInstruction;

  NavigationSession({
    required this.currentLatitude,
    required this.currentLongitude,
    required this.destinationName,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.navigationStatus,
    required this.currentInstruction,
    required this.nextInstruction,
  });
}
