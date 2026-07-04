import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../services/booking_api_service.dart';

/// Full-screen live tracking UI shown to the customer while the worker is en route.
/// Displays a real-time OpenStreetMap with the worker and customer locations.
/// Shows a 100m nearby alert and the completion OTP.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Nearby arrival animation
  late AnimationController _arrivalController;
  late Animation<double> _arrivalScale;
  late Animation<double> _arrivalOpacity;

  final MapController _mapController = MapController();

  static const LatLng _fallbackCustomerCenter = LatLng(22.5726, 88.3639);

  // OTP state
  String? _otp;
  bool _otpLoading = false;
  bool _otpVisible = false;
  String? _bookingId;

  // Nearby alert state
  bool _workerNearby = false;
  bool _arrivedAlertShown = false; // show once only

  @override
  void initState() {
    super.initState();

    // Pulse animation for the live badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Arrival burst animation
    _arrivalController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _arrivalScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _arrivalController, curve: Curves.elasticOut),
    );
    _arrivalOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _arrivalController, curve: Curves.easeIn),
    );

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Grab booking id from route args once
    if (_bookingId == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        _bookingId = args.toString();
        _fetchOtp();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _arrivalController.dispose();
    super.dispose();
  }

  Future<void> _fetchOtp() async {
    if (_bookingId == null) return;
    setState(() => _otpLoading = true);
    try {
      final otp = await BookingApiService().getCompletionOtp(_bookingId!);
      if (mounted) setState(() => _otp = otp);
    } catch (_) {
      // OTP not available yet — will retry on reveal
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _revealOtp() async {
    if (_otp != null) {
      setState(() => _otpVisible = !_otpVisible);
      return;
    }
    setState(() => _otpLoading = true);
    try {
      final otp = await BookingApiService().getCompletionOtp(_bookingId!);
      if (mounted) {
        setState(() {
          _otp = otp;
          _otpVisible = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch OTP: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  /// Haversine formula — returns distance in metres between two lat/lng points
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Earth radius in metres
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  void _checkProximity(List<double>? workerCoords, List<double>? customerCoords) {
    if (workerCoords == null || workerCoords.length < 2) return;
    if (customerCoords == null || customerCoords.length < 2) return;

    final dist = _haversineDistance(
      customerCoords[1], // lat  (GeoJSON: [lng, lat])
      customerCoords[0], // lng
      workerCoords[1],
      workerCoords[0],
    );

    final isNearby = dist < 100;
    if (isNearby != _workerNearby) {
      setState(() => _workerNearby = isNearby);
      if (isNearby && !_arrivedAlertShown) {
        _arrivedAlertShown = true;
        _arrivalController.forward(from: 0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bp, _) {
        final workerCoords = bp.workerCoordinates;
        final topInset = MediaQuery.of(context).padding.top;

        // Check 100m proximity whenever location updates
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkProximity(workerCoords, bp.trackingCustomerCoords);
        });

        // Auto-center camera on worker when location updates
        if (workerCoords != null && workerCoords.length == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(
              LatLng(workerCoords[1], workerCoords[0]),
              _mapController.camera.zoom > 10 ? _mapController.camera.zoom : 15.0,
            );
          });
        }

        return Scaffold(
          body: Stack(
            children: [
              // 1. The Map View
              _buildMapContent(bp),

              // 2. Custom App Bar overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _buildHeaderOverlay(bp),
              ),

              // 3. Blinking LIVE badge
              Positioned(
                top: topInset + 74,
                left: 16,
                child: _buildLiveBadge(),
              ),

              // 4. Info Card at the bottom (OTP + coords)
              Positioned(
                bottom: 24,
                left: 20,
                right: 20,
                child: _buildInfoCard(bp),
              ),

              // 5. Worker Arrived overlay (100m alert)
              if (_workerNearby)
                Positioned(
                  top: topInset + 114,
                  left: 20,
                  right: 20,
                  child: _buildNearbyAlert(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMapContent(BookingProvider bp) {
    final workerCoords = bp.workerCoordinates;
    final customerCoords = bp.trackingCustomerCoords;

    // Use the booked service address; fall back to Kolkata if coords not yet available
    final customerLatLng = (customerCoords != null && customerCoords.length == 2)
        ? LatLng(customerCoords[1], customerCoords[0]) // GeoJSON: [lng, lat]
        : _fallbackCustomerCenter;

    // Determine worker coordinate
    final workerLatLng = (workerCoords != null && workerCoords.length == 2)
        ? LatLng(workerCoords[1], workerCoords[0])
        : null;

    // Center map on worker if online, else center on customer
    final mapCenter = workerLatLng ?? customerLatLng;

    // Prepare markers
    final markers = <Marker>[
      // Customer location marker (Blue Pulsing Pin)
      Marker(
        point: customerLatLng,
        width: 60,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ],
        ),
      ),
    ];

    // Add worker marker if available (Green Pulsing Pin with directions/person icon)
    if (workerLatLng != null) {
      markers.add(
        Marker(
          point: workerLatLng,
          width: 80,
          height: 80,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 48 * _pulseAnimation.value,
                    height: 48 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Connect customer and worker with dotted line if both coordinates available
    final polylines = <Polyline>[];
    if (workerLatLng != null) {
      polylines.add(
        Polyline(
          points: [customerLatLng, workerLatLng],
          color: AppTheme.primary.withValues(alpha: 0.8),
          strokeWidth: 3.5,
          pattern: const StrokePattern.dotted(),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 15.0,
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.customer_app',
        ),
        if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildHeaderOverlay(BookingProvider bp) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withValues(alpha: 0.95),
            Colors.white.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Live Tracking',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Tracking your provider en route',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white,
            elevation: 4,
            shadowColor: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () {
                bp.resetTracking();
                Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.close_rounded, color: AppTheme.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBadge() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.15 * _pulseAnimation.value),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.4 * _pulseAnimation.value),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.6 * _pulseAnimation.value),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE TRACKING',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.success,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 100m nearby arrival banner
  Widget _buildNearbyAlert() {
    return AnimatedBuilder(
      animation: _arrivalController,
      builder: (context, _) {
        return Opacity(
          opacity: _arrivalOpacity.value,
          child: Transform.scale(
            scale: _arrivalScale.value,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.success,
                    AppTheme.success.withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.where_to_vote_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🎉  Worker has Arrived!',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your provider is within 100 metres',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(BookingProvider bp) {
    final coords = bp.workerCoordinates;
    final timestamp = bp.lastLocationTimestamp;
    final timeStr = timestamp != null
        ? _formatTimestamp(timestamp)
        : 'Waiting for provider location...';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status row
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.directions_car_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _workerNearby ? 'Worker Nearby!' : 'Provider En Route',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _workerNearby ? AppTheme.success : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (coords != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.success,
                    ),
                  ),
                ),
            ],
          ),

          // ── OTP Section ─────────────────────────────────────
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded,
                            size: 14, color: AppTheme.textMuted),
                        const SizedBox(width: 6),
                        Text(
                          'Job Completion OTP',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // OTP digits display
                    _otpLoading
                        ? const SizedBox(
                            height: 36,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          )
                        : _otpVisible && _otp != null && _otp!.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: _otp!.split('').map((digit) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 40,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        digit,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Text(
                                '● ● ● ●',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.textMuted,
                                  letterSpacing: 6,
                                ),
                              ),
                  ],
                ),
              ),
              // Show/hide OTP button
              GestureDetector(
                onTap: _revealOtp,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    _otpVisible ? 'Hide' : 'Show OTP',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (coords != null && coords.length == 2) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            // Coordinate display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.06)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _coordColumn(
                      'LONGITUDE',
                      coords[0].toStringAsFixed(6),
                      Icons.arrow_forward_rounded,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: AppTheme.textMuted.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: _coordColumn(
                      'LATITUDE',
                      coords[1].toStringAsFixed(6),
                      Icons.arrow_upward_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _coordColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(int timestamp) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
