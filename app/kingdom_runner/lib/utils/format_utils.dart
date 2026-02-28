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

// Format distance in appropriate units
String formatDistance(double distanceInMeters) {
  if (distanceInMeters < 1000) {
    return '${distanceInMeters.toStringAsFixed(0)} m';
  } else {
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }
}
