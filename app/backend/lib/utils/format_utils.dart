// Format area in appropriate units
String formatArea(double areaInM2) {
  if (areaInM2 < 1) {
    return '${(areaInM2 * 10000).toStringAsFixed(0)} cm²';
  } else if (areaInM2 < 10000) {
    return '${areaInM2.toStringAsFixed(2)} m²';
  } else if (areaInM2 < 1000000) {
    // Show in hectares for medium sizes
    return '${(areaInM2 / 10000).toStringAsFixed(3)} ha';
  } else {
    return '${(areaInM2 / 1000000).toStringAsFixed(4)} km²';
  }
}

// Format distance in appropriate units (cm → m → km)
String formatDistance(double distanceInMeters) {
  if (distanceInMeters < 0.01) {
    // Less than 1cm, show in cm with decimals
    return '${(distanceInMeters * 100).toStringAsFixed(2)} cm';
  } else if (distanceInMeters < 1) {
    // Less than 1m, show in cm
    return '${(distanceInMeters * 100).toStringAsFixed(0)} cm';
  } else if (distanceInMeters < 1000) {
    // Less than 1km, show in meters
    return '${distanceInMeters.toStringAsFixed(2)} m';
  } else {
    // 1km or more, show in km
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }
}
