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
    print("Place marks: $placemarks");

    if (placemarks.isNotEmpty) {
      final placemark = placemarks.first;
      print("📍 Placemark completo: $placemark");

      // 1. Tenta pegar o nome do local (POI)
      if (placemark.name != null && placemark.name!.isNotEmpty) {
        print("✔️ Usando POI (name): ${placemark.name}");
        return placemark.name;
      }

      // 2. Fallbacks:
      if (placemark.locality != null && placemark.locality!.isNotEmpty) {
        print("✔️ Usando cidade (locality): ${placemark.locality}");
        return placemark.locality;
      }

      if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
        print("✔️ Usando bairro (subLocality): ${placemark.subLocality}");
        return placemark.subLocality;
      }

      if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
        print("✔️ Usando rua (thoroughfare): ${placemark.thoroughfare}");
        return placemark.thoroughfare;
      }

      if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
        print("✔️ Usando estado (administrativeArea): ${placemark.administrativeArea}");
        return placemark.administrativeArea;
      }
    }
  } catch (e) {
    print('❌ Erro ao buscar nome do local: $e');
  }
  return null;
}


