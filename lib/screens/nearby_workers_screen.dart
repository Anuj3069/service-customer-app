import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../config/theme.dart';
import '../models/service.dart';
import '../models/nearby_worker.dart';
import '../services/nearby_workers_service.dart';
import '../utils/location_helper.dart';

class NearbyWorkersScreen extends StatefulWidget {
  const NearbyWorkersScreen({super.key});

  @override
  State<NearbyWorkersScreen> createState() => _NearbyWorkersScreenState();
}

class _NearbyWorkersScreenState extends State<NearbyWorkersScreen> {
  final NearbyWorkersService _workersService = NearbyWorkersService();
  final MapController _mapController = MapController();
  final PageController _pageController = PageController(viewportFraction: 0.85);

  Category? _category;
  Position? _currentPosition;
  List<NearbyWorker> _workers = [];
  bool _isLoadingLocation = true;
  bool _isLoadingWorkers = false;
  String? _errorMessage;
  int _selectedWorkerIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initLocationAndWorkers();

    // Auto-refresh nearby workers every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted ||
          _isLoadingWorkers ||
          _currentPosition == null ||
          _category == null) {
        return;
      }
      _fetchWorkers();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initLocationAndWorkers() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationHelper.getCurrentLocation();
      if (position != null) {
        _currentPosition = position;
      } else {
        _errorMessage =
            'Location access is required to show nearby pros. Please enable location services and grant permission.';
      }
    } catch (e) {
      _errorMessage =
          'Could not retrieve location. Please check your settings.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        if (_currentPosition != null) {
          _fetchWorkers();
        }
      }
    }
  }

  Future<void> _fetchWorkers() async {
    if (_category == null || _currentPosition == null) return;

    setState(() {
      _isLoadingWorkers = true;
    });

    try {
      final workers = await _workersService.getNearbyWorkers(
        categoryId: _category!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        radiusKm: 15.0, // Expanded radius for better demonstration
      );

      if (mounted) {
        setState(() {
          _workers = workers;
          _isLoadingWorkers = false;
        });

        // Center map on customer or first worker if available
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (workers.isNotEmpty) {
            _animateToWorker(0);
          } else {
            _mapController.move(
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
              13.5,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingWorkers = false;
          _errorMessage = 'Failed to load nearby workers: ${e.toString()}';
        });
      }
    }
  }

  void _animateToWorker(int index) {
    if (index < 0 || index >= _workers.length) return;
    setState(() {
      _selectedWorkerIndex = index;
    });
    final worker = _workers[index];
    _mapController.move(LatLng(worker.latitude, worker.longitude), 14.5);
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve category from arguments
    if (_category == null) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is Category) {
        _category = args;
      }
    }

    if (_category == null) {
      return const Scaffold(body: Center(child: Text('Invalid Category')));
    }

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // 1. The Map View / Error state
          _isLoadingLocation
              ? _buildLoadingState()
              : (_currentPosition == null
                    ? _buildLocationErrorState()
                    : _buildMapContent()),

          // 2. Custom App Bar overlay
          Positioned(top: 0, left: 0, right: 0, child: _buildHeaderOverlay()),

          // 3. Floating Quick Info badges
          if (!_isLoadingLocation && !_isLoadingWorkers && _workers.isNotEmpty)
            Positioned(
              top: topInset + 74,
              right: 16,
              child: _buildWorkerCountOverlay(),
            ),

          // 4. Worker Horizontal PageView at the bottom
          if (!_isLoadingLocation && _workers.isNotEmpty)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 180,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _workers.length,
                  onPageChanged: (index) {
                    _animateToWorker(index);
                  },
                  itemBuilder: (context, index) {
                    return _buildWorkerCard(_workers[index], index);
                  },
                ),
              ),
            ),

          // 5. Empty State or Error Banner
          if (!_isLoadingLocation &&
              _currentPosition != null &&
              (_workers.isEmpty || _errorMessage != null) &&
              !_isLoadingWorkers)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: _buildEmptyState(),
            ),

          // 6. Loading overlay for background refresh
          if (_isLoadingWorkers && _workers.isNotEmpty)
            Positioned(
              top: topInset + 74,
              left: 16,
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
            const SizedBox(height: 20),
            Text(
              'Locating nearby pros...',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationErrorState() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 72, color: AppTheme.error),
            const SizedBox(height: 20),
            Text(
              'Location Required',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ??
                  'Please enable location services to see nearby professionals.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _initLocationAndWorkers,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Retry location',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapContent() {
    final customerLatLng = LatLng(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
    );

    // Prepare list of markers
    final markers = <Marker>[
      // Customer location marker
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

    // Add active workers markers
    for (int i = 0; i < _workers.length; i++) {
      final worker = _workers[i];
      final isSelected = i == _selectedWorkerIndex;
      markers.add(
        Marker(
          point: LatLng(worker.latitude, worker.longitude),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                i,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
              _animateToWorker(i);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulsing dot for selected worker
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 48 : 36,
                  height: isSelected ? 48 : 36,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(
                      alpha: isSelected ? 0.3 : 0.15,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: isSelected ? 36 : 28,
                  height: isSelected ? 36 : 28,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.success : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : AppTheme.success,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: isSelected ? Colors.white : AppTheme.success,
                    size: isSelected ? 20 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: customerLatLng,
        initialZoom: 13.5,
        maxZoom: 18.0,
        minZoom: 10.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.customer_app',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildHeaderOverlay() {
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
            shadowColor: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppTheme.textPrimary,
                ),
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
                  'Nearby ${_category?.name ?? 'Pros'}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Real-time active professionals',
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
            shadowColor: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _initLocationAndWorkers,
              borderRadius: BorderRadius.circular(16),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.my_location_rounded, color: AppTheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCountOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, color: AppTheme.success, size: 10),
          const SizedBox(width: 6),
          Text(
            '${_workers.length} Pros online',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerCard(NearbyWorker worker, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Avatar / Status indicator
          Stack(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: AppTheme.bgCardLight,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: AppTheme.primary,
                  size: 32,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppTheme.success,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Center: Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  worker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppTheme.warning,
                      size: 16,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${worker.rating.toStringAsFixed(1)} ',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '(${worker.totalJobs} jobs)',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppTheme.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${worker.distance.toStringAsFixed(2)} km away',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right: Book Button
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => _showServiceSelectionModal(worker),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Book',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _errorMessage != null
                ? Icons.error_outline_rounded
                : Icons.location_off_rounded,
            color: _errorMessage != null ? AppTheme.error : AppTheme.textMuted,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage != null
                ? 'Error Loading Pros'
                : 'No Active Pros Nearby',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ??
                'Currently there are no active service providers online in this area. Please try again later.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceSelectionModal(NearbyWorker worker) {
    if (_category == null || _category!.services.isEmpty) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 24,
            right: 24,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pull bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppTheme.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose a Service',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Select which service you want to book from ${worker.name}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _category!.services.length,
                  itemBuilder: (context, index) {
                    final service = _category!.services[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.bgDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        title: Text(
                          service.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Duration: ${service.duration} mins',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₹${service.basePrice.toInt()}',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                        onTap: () {
                          // Close modal and navigate to Service Detail
                          Navigator.pop(context);
                          Navigator.pushNamed(
                            context,
                            '/service-detail',
                            arguments: service,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
