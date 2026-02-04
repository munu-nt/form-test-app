import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';
class GpsLocationWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const GpsLocationWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<GpsLocationWidget> createState() => _GpsLocationWidgetState();
}
class _GpsLocationWidgetState extends State<GpsLocationWidget> {
  LocationData? _location;
  bool _isLoading = false;
  String? _errorMessage;
  LocationPermission? _permission;
  final MapController _mapController = MapController();
  bool _isMapReady = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermission();
    });
  }
  Future<void> _checkPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (!mounted) return;
      setState(() {
        _permission = permission;
      });
    } catch (e) {
      debugPrint('Check permission error: $e');
    }
  }
  Future<void> _requestPermission() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) return;
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isLoading = false;
        });
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (!mounted) return;
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission denied by user.';
            _permission = permission;
            _isLoading = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied. Please enable in app settings.';
          _permission = permission;
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _permission = permission;
      });
      if (!mounted) return;
      await _getCurrentLocation();
    } catch (e, stack) {
      debugPrint('Permission error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      String? address;
      String? city;
      String? country;
      String? postalCode;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          address = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          city = place.locality;
          country = place.country;
          postalCode = place.postalCode;
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }
      if (!mounted) return;
      final locationData = LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        address: address,
        city: city,
        country: country,
        postalCode: postalCode,
      );
      setState(() {
        _location = locationData;
        _isLoading = false;
      });
      widget.onValueChanged(widget.field.fieldId, locationData.toJson());
      if (_isMapReady) {
        _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.location_on, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.field.fieldName, style: theme.textTheme.titleMedium)),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          if (_errorMessage != null)
            _buildErrorState(theme)
          else if (_location != null)
            _buildLocationContent(theme)
          else
            _buildInitialState(theme),
        ],
      ),
    );
  }
  Widget _buildLocationContent(ThemeData theme) {
    final latLng = LatLng(_location!.latitude, _location!.longitude);
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: latLng,
              initialZoom: 15.0,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              onMapReady: () {
                _isMapReady = true;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.test_1',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: latLng,
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.location_pin,
                      color: theme.colorScheme.primary,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_location!.address != null) ...[
                Text(
                  'Address',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
                ),
                Text(_location!.address!, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
              ],
              Text(
                'Lat: ${_location!.latitude.toStringAsFixed(6)}, Lng: ${_location!.longitude.toStringAsFixed(6)}',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 12),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Update Location'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  Widget _buildErrorState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
          FilledButton.tonal(
            onPressed: _requestPermission,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
  Widget _buildInitialState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.location_searching, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _requestPermission,
              child: const Text('Get My Location'),
            ),
          ],
        ),
      ),
    );
  }
}