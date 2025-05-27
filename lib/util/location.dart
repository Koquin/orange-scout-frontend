import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';


Future<Map<String, dynamic>?> getCurrentLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    print('Localization service desabled');
    return null;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      print('Location permission denied');
      return null;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    print('Location permission denied permanently');
    return null;
  }

  Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

  String? placeName = await getPlaceName(position.latitude, position.longitude);
  print("Position: $position");
  print("Place name: $placeName");

  return {
    'latitude': position.latitude,
    'longitude': position.longitude,
    'placeName': placeName,
  };
}

Future<String?> getPlaceName(double latitude, double longitude) async {
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      if (placemark.name != null && placemark.name!.isNotEmpty) {
        return placemark.name;
      }

      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        return placemark.locality;
      }

      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        return placemark.subLocality;
      }

      if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
        return placemark.thoroughfare;
      }

      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        return placemark.administrativeArea;
      }
    }
  } catch (e) {
    print('Error fetching location name: $e');
  }
  return null;
}


