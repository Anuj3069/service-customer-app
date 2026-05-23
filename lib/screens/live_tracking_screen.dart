import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';

/// Full-screen live tracking UI shown to the customer while the worker is en route.
/// Displays an animated radar-style visualization with live coordinate updates.
class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;
  late AnimationController _markerController;
  late Animation<double> _pulseAnimation;

  // For smooth marker animation
  List<double>? _previousCoords;
  List<double>? _currentCoords;

  @override
  void initState() {
    super.initState();

    // Radar sweep animation — continuous rotation
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Pulse animation for the live badge
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Marker position animation for smooth transitions
    _markerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bp, _) {
        // Animate marker when coordinates change
        if (bp.workerCoordinates != null &&
            bp.workerCoordinates != _currentCoords) {
          _previousCoords = _currentCoords;
          _currentCoords = bp.workerCoordinates;
          _markerController
            ..reset()
            ..forward();
        }

        return Scaffold(
          body: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F1628), Color(0xFF1A2342), Color(0xFF0D1220)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(bp),
                  const SizedBox(height: 8),
                  _buildLiveBadge(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildRadarView(bp)),
                  _buildInfoCard(bp),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BookingProvider bp) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          ),
          Expanded(
            child: Text(
              'Live Tracking',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Stop tracking button
          IconButton(
            onPressed: () {
              bp.resetTracking();
              Navigator.pop(context);
            },
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.success.withValues(alpha: 0.15 * _pulseAnimation.value),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppTheme.success.withValues(alpha: 0.4 * _pulseAnimation.value),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.success,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.6 * _pulseAnimation.value),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE TRACKING',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.success,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRadarView(BookingProvider bp) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth - 48, constraints.maxHeight - 48);
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: Listenable.merge([_radarController, _markerController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: _RadarPainter(
                    sweepAngle: _radarController.value * 2 * pi,
                    workerCoords: _currentCoords,
                    previousCoords: _previousCoords,
                    markerProgress: _markerController.value,
                    hasData: bp.workerCoordinates != null,
                  ),
                );
              },
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
        : 'Waiting for update...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          children: [
            // Status row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4B82E8), Color(0xFF64B5F6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Provider En Route',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeStr,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (coords != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.success,
                      ),
                    ),
                  ),
              ],
            ),
            if (coords != null) ...[
              const SizedBox(height: 20),
              // Coordinate display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
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
                      height: 40,
                      color: Colors.white.withValues(alpha: 0.1),
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
            Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
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

// ═══════════════════════════════════════════════════════════════
// Radar-style Custom Painter
// ═══════════════════════════════════════════════════════════════

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final List<double>? workerCoords;
  final List<double>? previousCoords;
  final double markerProgress;
  final bool hasData;

  _RadarPainter({
    required this.sweepAngle,
    this.workerCoords,
    this.previousCoords,
    required this.markerProgress,
    required this.hasData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background circles (concentric rings)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 1; i <= 4; i++) {
      final r = radius * i / 4;
      ringPaint.color = Colors.white.withValues(alpha: 0.08);
      canvas.drawCircle(center, r, ringPaint);
    }

    // Cross-hair lines
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      crossPaint,
    );

    // Diagonal cross-hairs
    final diagOffset = radius * 0.707; // cos(45°)
    canvas.drawLine(
      Offset(center.dx - diagOffset, center.dy - diagOffset),
      Offset(center.dx + diagOffset, center.dy + diagOffset),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx + diagOffset, center.dy - diagOffset),
      Offset(center.dx - diagOffset, center.dy + diagOffset),
      crossPaint,
    );

    // Radar sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          const Color(0xFF4B82E8).withValues(alpha: 0.3),
        ],
        transform: GradientRotation(sweepAngle - 0.8),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep line
    final sweepLinePaint = Paint()
      ..color = const Color(0xFF4B82E8).withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * cos(sweepAngle),
        center.dy + radius * sin(sweepAngle),
      ),
      sweepLinePaint,
    );

    // Center point (customer location)
    final centerDotPaint = Paint()
      ..color = const Color(0xFF36A56D);
    canvas.drawCircle(center, 6, centerDotPaint);

    final centerRingPaint = Paint()
      ..color = const Color(0xFF36A56D).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 12, centerRingPaint);

    // Worker marker (if we have coordinates)
    if (workerCoords != null && hasData) {
      // Map coordinates to a position within the radar
      // Use a simple approach: offset from center based on coordinate deltas
      Offset markerPos;

      if (previousCoords != null && markerProgress < 1.0) {
        // Interpolate between previous and current position
        final prevX = _coordToOffset(previousCoords![0], radius);
        final prevY = _coordToOffset(previousCoords![1], radius);
        final currX = _coordToOffset(workerCoords![0], radius);
        final currY = _coordToOffset(workerCoords![1], radius);

        markerPos = Offset(
          center.dx + _lerp(prevX, currX, markerProgress),
          center.dy - _lerp(prevY, currY, markerProgress),
        );
      } else {
        markerPos = Offset(
          center.dx + _coordToOffset(workerCoords![0], radius),
          center.dy - _coordToOffset(workerCoords![1], radius),
        );
      }

      // Glow ring
      final glowPaint = Paint()
        ..color = const Color(0xFF4B82E8).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(markerPos, 18, glowPaint);

      // Outer ring
      final outerRing = Paint()
        ..color = const Color(0xFF4B82E8).withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(markerPos, 14, outerRing);

      // Worker dot
      final workerPaint = Paint()
        ..color = const Color(0xFF4B82E8);
      canvas.drawCircle(markerPos, 8, workerPaint);

      // Inner white dot
      final innerPaint = Paint()
        ..color = Colors.white;
      canvas.drawCircle(markerPos, 3, innerPaint);
    }

    // Outer border ring
    final borderPaint = Paint()
      ..color = const Color(0xFF4B82E8).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius, borderPaint);
  }

  double _coordToOffset(double coord, double radius) {
    // Map coordinate to radar space
    // Use modulo to keep within bounds, centered around a reference
    final normalized = ((coord % 1.0) - 0.5) * 2; // -1 to 1
    return normalized * radius * 0.6;
  }

  double _lerp(double a, double b, double t) {
    return a + (b - a) * t;
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.workerCoords != workerCoords ||
        oldDelegate.markerProgress != markerProgress;
  }
}
