class Address {
  final String displayName;
  final double lat;
  final double lon;

  Address({required this.displayName, required this.lat, required this.lon});

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      displayName: json["display_name"],
      // Parse lat/lon to double to avoid type errors
      lat: double.tryParse(json["lat"] ?? '') ?? 0.0,
      lon: double.tryParse(json["lon"] ?? '') ?? 0.0,
    );
  }
}
