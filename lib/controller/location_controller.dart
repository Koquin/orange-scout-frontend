import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../dto/error_response_dto.dart';
import '../dto/location_dto.dart';

class LocationController {
  final String? _baseUrl = dotenv.env['API_BASE_URL'];
  final http.Client _httpClient; // Use an injected http client for testing

  LocationController({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  String _getApiBaseUrl() {
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      FirebaseCrashlytics.instance.recordError(
        'API base URL not configured.',
        StackTrace.current,
        reason: 'Location service configuration error',
        fatal: false,
      );
      throw Exception('API base URL not configured in .env file.');
    }
    return _baseUrl!;
  }

  // Helper to parse backend error responses (same as in AuthController)
  String _parseBackendErrorMessage(http.Response response) {
    try {
      final Map<String, dynamic> errorData = jsonDecode(response.body);
      // Assuming ErrorResponse DTO exists in Flutter
      final errorResponse = ErrorResponse.fromJson(errorData);

      if (errorResponse.message != null && errorResponse.message!.isNotEmpty) {
        return errorResponse.message!;
      }
      if (errorResponse.error != null && errorResponse.error!.isNotEmpty) {
        return errorResponse.error!;
      }
      if (errorResponse.details != null && errorResponse.details!.isNotEmpty) {
        return errorResponse.details!.values.join('\n');
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error parsing backend error response in LocationController',
        information: [response.body, response.statusCode.toString()],
        fatal: false,
      );
      return 'An unexpected error occurred parsing server response. Status: ${response.statusCode}';
    }
    return 'An unknown error occurred. Status: ${response.statusCode}';
  }

  // --- Location Utility Methods (Client-Side) ---

  Future<String?> getPlaceNameFromCoordinates(double latitude, double longitude) async {
    FirebaseCrashlytics.instance.log('Attempting to get place name from coordinates: $latitude, $longitude');
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Prioritize locality, then subLocality, then name
        String? location = place.locality;
        if (location != null && location.isNotEmpty) return location;

        location = place.subLocality;
        if (location != null && location.isNotEmpty) return location;

        location = place.name;
        if (location != null && location.isNotEmpty) return location;
      }
      FirebaseCrashlytics.instance.log('No place name found for coordinates: $latitude, $longitude');
      return null;
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error getting place name from geocoding service',
        information: ['Latitude: $latitude', 'Longitude: $longitude'],
        fatal: false,
      );
      return null;
    }
  }

  Future<LocationDTO?> getCurrentLocationData() async {
    FirebaseAnalytics.instance.logEvent(name: 'get_current_location_attempt');
    FirebaseCrashlytics.instance.log('Attempting to get current device location.');

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      FirebaseCrashlytics.instance.log('Location service disabled on device.');
      // Consider throwing a custom exception or returning a specific error state
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        FirebaseCrashlytics.instance.log('Location permission denied by user.');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      FirebaseCrashlytics.instance.log('Location permission denied permanently by user.');
      // Advise user to go to settings
      return null;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 0,
          )
      );

      String? venueName = await getPlaceNameFromCoordinates(position.latitude, position.longitude);

      FirebaseCrashlytics.instance.log('Current location obtained: ${position.latitude}, ${position.longitude}');
      return LocationDTO(
        latitude: position.latitude,
        longitude: position.longitude,
        venueName: venueName ?? 'Localização Desconhecida', // Provide a fallback name
      );
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Error getting current device position',
        fatal: true, // This could be a critical issue for core functionality
      );
      return null;
    }
  }

  // --- Backend API Calls ---

  /// Retrieves a specific location by ID from the backend.
  /// Returns LocationDTO on success, null on failure.
  Future<LocationDTO?> getLocationById(int locationId) async {
    FirebaseAnalytics.instance.logEvent(name: 'get_location_by_id_attempt', parameters: {'location_id': locationId});
    FirebaseCrashlytics.instance.log('Attempting to get location for ID: $locationId from backend.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('No token found for getLocationById. User might be logged out.');
      return null; // Or throw an Unauthorized exception
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/locations/$locationId'); // PADRONIZAÇÃO: /locations/{id}
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final locationDTO = LocationDTO.fromJson(jsonDecode(response.body));
        FirebaseCrashlytics.instance.log('Location ID: $locationId retrieved successfully.');
        return locationDTO;
      } else if (response.statusCode == 404) {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.log('Location ID: $locationId not found. Message: $errorMessage');
        return null; // ResourceNotFoundException in backend translates to null here
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to retrieve location: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for getLocationById',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return null;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error retrieving location by ID',
        fatal: false,
      );
      return null;
    }
  }

  /// Opens a specific match location on Google Maps.
  /// First fetches the location details from the backend.
  /// Returns true if opened successfully, false otherwise.
  Future<bool> openMatchLocationOnMaps(int locationId) async {
    FirebaseAnalytics.instance.logEvent(name: 'open_match_location_attempt', parameters: {'location_id': locationId});
    FirebaseCrashlytics.instance.log('Attempting to open match location for Location ID: $locationId on maps.');

    final locationData = await getLocationById(locationId); // Reuse existing method
    if (locationData == null) {
      FirebaseCrashlytics.instance.log('Location data not found for ID: $locationId. Cannot open maps.');
      return false;
    }

    final String googleMapsUrl;
    // Build Google Maps URL
    // Use the `venueName` for a better search experience if available
    if (locationData.venueName.isNotEmpty) {
      googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}';
    } else {
      googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${locationData.latitude},${locationData.longitude}';
    }

    final Uri uri = Uri.parse(googleMapsUrl);

    if (await canLaunchUrl(uri)) { // Use uri instead of googleMapsUrl string directly in canLaunchUrl
      await launchUrl(uri, mode: LaunchMode.externalApplication); // Use externalApplication for maps
      FirebaseAnalytics.instance.logEvent(
        name: 'match_location_opened_successfully',
        parameters: {'location_id': locationId, 'latitude': locationData.latitude, 'longitude': locationData.longitude},
      );
      FirebaseCrashlytics.instance.log('Match location opened successfully for ID: $locationId.');
      return true;
    } else {
      FirebaseCrashlytics.instance.recordError(
        'Could not launch Google Maps URL.',
        StackTrace.current,
        reason: 'URL launcher failed for match location',
        information: [uri.toString()],
        fatal: false,
      );
      FirebaseAnalytics.instance.logEvent(
        name: 'open_match_location_failed',
        parameters: {
          'location_id': locationId,
          'reason': 'url_launcher_failed'
        },
      );
      return false;
    }
  }

  /// Opens all match locations on Google Maps, potentially with waypoints.
  /// Fetches all locations from the backend first.
  /// Returns true if opened successfully, false otherwise.
  Future<bool> openAllMatchLocationsOnMaps() async {
    FirebaseAnalytics.instance.logEvent(name: 'open_all_locations_attempt');
    FirebaseCrashlytics.instance.log('Attempting to open all match locations on maps.');

    final String? token = await loadToken();
    if (token == null) {
      FirebaseCrashlytics.instance.log('Token not found for opening all match locations. User might be logged out.');
      return false;
    }

    try {
      final url = Uri.parse('${_getApiBaseUrl()}/locations'); // PADRONIZAÇÃO: /locations para buscar todas
      final response = await _httpClient.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonLocations = jsonDecode(response.body);
        final List<LocationDTO> locations = jsonLocations.map((json) => LocationDTO.fromJson(json)).toList();

        if (locations.isEmpty) {
          FirebaseAnalytics.instance.logEvent(name: 'open_all_locations_no_data');
          FirebaseCrashlytics.instance.log('No locations found to open on maps.');
          return false;
        }

        String googleMapsUrl;
        if (locations.length == 1) {
          final loc = locations[0];
          googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${loc.latitude},${loc.longitude}';
        } else {
          // For multiple locations, build a directions URL with waypoints
          // Google Maps URL scheme: https://www.google.com/maps/dir/?api=1&origin=...&destination=...&waypoints=...
          // A simpler approach for multiple markers on a map, not directions:
          // Just list all coords, maps usually shows them: https://www.google.com/maps/search/?api=1&query=lat1,lon1;lat2,lon2
          final String query = locations.map((loc) => '${loc.latitude},${loc.longitude}').join(';');
          googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$query';
        }

        final Uri uri = Uri.parse(googleMapsUrl);

        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          FirebaseAnalytics.instance.logEvent(name: 'all_locations_opened_successfully', parameters: {'count': locations.length});
          FirebaseCrashlytics.instance.log('All locations opened successfully. Count: ${locations.length}');
          return true;
        } else {
          FirebaseCrashlytics.instance.recordError(
            'Could not launch Google Maps URL for all locations.',
            StackTrace.current,
            reason: 'URL launcher failed for all locations',
            information: [uri.toString()],
            fatal: false,
          );
          FirebaseAnalytics.instance.logEvent(name: 'open_all_locations_failed', parameters: {'reason': 'url_launcher_failed'});
          return false;
        }
      } else {
        final errorMessage = _parseBackendErrorMessage(response);
        FirebaseCrashlytics.instance.recordError(
          'Failed to fetch all locations: ${response.statusCode}',
          StackTrace.current,
          reason: 'Backend response error for fetching all locations',
          information: [response.body, response.request?.url.toString() ?? ''],
          fatal: false,
        );
        return false;
      }
    } catch (e, s) {
      FirebaseCrashlytics.instance.recordError(
        e, s,
        reason: 'Connection error fetching all match locations',
        fatal: false,
      );
      return false;
    }
  }

}