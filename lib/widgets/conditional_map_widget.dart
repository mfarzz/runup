import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ConditionalMapWidget extends StatefulWidget {
  final CameraPosition initialCameraPosition;
  final Set<Polyline> polylines;
  final Set<Marker> markers;
  final Function(GoogleMapController)? onMapCreated;
  final Function(CameraPosition)? onCameraMove;

  const ConditionalMapWidget({
    Key? key,
    required this.initialCameraPosition,
    this.polylines = const {},
    this.markers = const {},
    this.onMapCreated,
    this.onCameraMove,
  }) : super(key: key);

  @override
  State<ConditionalMapWidget> createState() => _ConditionalMapWidgetState();
}

class _ConditionalMapWidgetState extends State<ConditionalMapWidget> {
  bool _isMapLoading = true;
  bool _hasMapError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    try {
      // Give some time for web Google Maps API to load
      if (kIsWeb) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      if (mounted) {
        setState(() {
          _isMapLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isMapLoading = false;
          _hasMapError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ConditionalMapWidget: Building map widget');
    print('Platform: ${defaultTargetPlatform.toString()}');
    print('Is Web: $kIsWeb');
    print('Is Loading: $_isMapLoading');
    print('Has Error: $_hasMapError');
    print('Initial camera position: ${widget.initialCameraPosition.target}');
    
    if (_isMapLoading) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_hasMapError) {
      print('ConditionalMapWidget: Showing fallback due to error: $_errorMessage');
      return _buildWebFallback();
    }
    
    // Always try to use Google Maps first, regardless of platform
    // The Google Maps API key is already configured in index.html for web
    print('ConditionalMapWidget: Using Google Maps');
    return _buildGoogleMap();
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: widget.initialCameraPosition,
      polylines: widget.polylines,
      markers: widget.markers,
      onMapCreated: (GoogleMapController controller) {
        print('ConditionalMapWidget: Google Map created successfully');
        if (widget.onMapCreated != null) {
          widget.onMapCreated!(controller);
        }
      },
      onCameraMove: widget.onCameraMove,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapType: MapType.normal,
      // Only apply custom style on mobile to avoid web compatibility issues
      style: kIsWeb ? null : _getMapStyle(),
    );
  }

  String? _getMapStyle() {
    // Return dark theme map style for better UI consistency
    return '''
    [
      {
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#212121"
          }
        ]
      },
      {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#9e9e9e"
          }
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "stylers": [
          {
            "visibility": "off"
          }
        ]
      },
      {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#bdbdbd"
          }
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#181818"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
          {
            "color": "#1b1b1b"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
          {
            "color": "#2c2c2c"
          }
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#8a8a8a"
          }
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#373737"
          }
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#3c3c3c"
          }
        ]
      },
      {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#4e4e4e"
          }
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#616161"
          }
        ]
      },
      {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#757575"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {
            "color": "#000000"
          }
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {
            "color": "#3d3d3d"
          }
        ]
      }
    ]
    ''';
  }

  Widget _buildWebFallback() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
            Colors.blue.shade500,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.5),
                radius: 1.5,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Grid pattern
          CustomPaint(
            size: Size.infinite,
            painter: GridPainter(),
          ),
          
          // Center info
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map_outlined,
                  size: 64,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  'Map View',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tracking your route',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Stats placeholder
                if (widget.polylines.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timeline,
                          color: Colors.white.withOpacity(0.9),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Route recorded',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Location indicator
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.gps_fixed,
                color: Colors.white.withOpacity(0.9),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    const gridSize = 50.0;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
