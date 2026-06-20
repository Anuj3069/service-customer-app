import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../utils/cancellation_reason_helper.dart';
import '../widgets/gradient_button.dart';

/// Full-screen waiting UI shown while an instant booking searches for a provider.
/// Listens for booking-confirmed / booking-expired socket events.
class InstantBookingScreen extends StatefulWidget {
  const InstantBookingScreen({super.key});

  @override
  State<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingScreenState extends State<InstantBookingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  late Animation<double> _pulseAnimation;

  Timer? _countdownTimer;
  Timer? _elapsedTimer;
  int _secondsRemaining = 300; // Default 5 minutes, synced with Redis TTL
  int _elapsedSeconds = 0;
  bool _canceling = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sync countdown with Redis TTL via booking's expiresAt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BookingProvider>();
      final booking = bp.instantBooking;
      if (booking?.expiresAt != null) {
        try {
          final expiry = DateTime.parse(booking!.expiresAt!);
          final diff = expiry.difference(DateTime.now());
          setState(() {
            _secondsRemaining = diff.inSeconds > 0 ? diff.inSeconds : 0;
          });
        } catch (_) {}
      }
    });

    // Start countdown
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });

    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });

    // Listen for tracking to auto-navigate to live tracking screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = context.read<BookingProvider>();
      bp.addListener(_onTrackingChanged);
    });
  }

  void _onTrackingChanged() {
    if (!mounted) return;
    final bp = context.read<BookingProvider>();
    if (bp.isTracking && bp.trackingBookingId != null) {
      bp.removeListener(_onTrackingChanged);
      Navigator.pushNamed(
        context,
        '/live-tracking',
        arguments: bp.trackingBookingId,
      );
    }
  }

  @override
  void dispose() {
    // Remove tracking listener
    try {
      context.read<BookingProvider>().removeListener(_onTrackingChanged);
    } catch (_) {}
    _pulseController.dispose();
    _rotateController.dispose();
    _countdownTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  String get _elapsedTime {
    final min = _elapsedSeconds ~/ 60;
    final sec = _elapsedSeconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  Future<void> _cancelInstantBooking(BookingProvider bp) async {
    final booking = bp.instantBooking;
    if (booking == null || _canceling) return;

    final reason = await showCancellationReasonPicker(context);
    if (reason == null || !mounted) return;

    setState(() => _canceling = true);
    final success = await bp.cancelBooking(
      booking.id,
      cancellationReason: reason,
    );

    if (!mounted) return;
    setState(() => _canceling = false);

    if (success) {
      _countdownTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking request cancelled.'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bp.error ?? 'Failed to cancel booking request'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BookingProvider>(
      builder: (context, bp, _) {
        final status = bp.instantStatus;

        return PopScope(
          canPop: status != 'searching',
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
              child: SafeArea(child: _buildContent(status, bp)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(String status, BookingProvider bp) {
    switch (status) {
      case 'confirmed':
        return _buildConfirmedView(bp);
      case 'expired':
        return _buildExpiredView();
      case 'tracking':
        // If somehow still on this screen when tracking, redirect
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && bp.trackingBookingId != null) {
            Navigator.pushNamed(
              context,
              '/live-tracking',
              arguments: bp.trackingBookingId,
            );
          }
        });
        return _buildConfirmedView(bp);
      default:
        return _buildLiveMatchingView(bp);
    }
  }

  // ── Searching View ──────────────────────────────────
  // ignore: unused_element
  Widget _buildSearchingView(BookingProvider bp) {
    final booking = bp.instantBooking;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated pulse rings
          SizedBox(
            width: 200,
            height: 200,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Transform.scale(
                      scale: _pulseAnimation.value * 1.1,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Middle ring
                    Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3),
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                    // Center icon
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Finding a professional...',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We\'re notifying nearby professionals.\nThe first one to accept gets your job.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Service info chip
          if (booking != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '₹${booking.price.toInt()}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          const SizedBox(height: 28),

          // Countdown timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timer_rounded, color: AppTheme.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Expires in $_formattedTime',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GradientButton(
            text: 'Cancel Request',
            icon: Icons.cancel_rounded,
            isLoading: _canceling,
            gradient: const LinearGradient(
              colors: [AppTheme.error, Color(0xFFC62828)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            onPressed: booking == null || _canceling
                ? null
                : () => _cancelInstantBooking(bp),
          ),
        ],
      ),
    );
  }

  // ── Confirmed View ──────────────────────────────────
  Widget _buildLiveMatchingView(BookingProvider bp) {
    final booking = bp.instantBooking;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMatchingMap(booking),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Finding nearby professional...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: _buildElapsedTimer()),
                const SizedBox(height: 18),
                if (booking != null) _buildCurrentBookingCard(booking),
                const SizedBox(height: 18),
                _buildMatchingSteps(bp),
                const SizedBox(height: 18),
                _buildExpiryStrip(),
                const SizedBox(height: 18),
                GradientButton(
                  text: 'Cancel Request',
                  icon: Icons.cancel_rounded,
                  isLoading: _canceling,
                  gradient: const LinearGradient(
                    colors: [AppTheme.error, Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  onPressed: booking == null || _canceling
                      ? null
                      : () => _cancelInstantBooking(bp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingMap(Booking? booking) {
    final title = booking == null
        ? 'Select Service'
        : 'Select Service • ${booking.serviceName}';

    return SizedBox(
      height: 340,
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _MatchingMapPainter())),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, _) => CustomPaint(
                painter: _MatchingPulsePainter(_pulseAnimation.value),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Container(
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: AppTheme.textPrimary,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
          Positioned(right: 14, top: 76, child: _prosOnlineBadge()),
          Positioned(left: 36, top: 172, child: _workerEtaPin('2 mins', 'A')),
          Positioned(right: 36, top: 180, child: _workerEtaPin('4 mins', 'R')),
          Positioned(
            left: 0,
            right: 0,
            top: 172,
            child: Center(child: _customerLocationDot()),
          ),
          Positioned(right: 16, bottom: 18, child: _mapLocateButton()),
        ],
      ),
    );
  }

  Widget _prosOnlineBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Nearby Pros',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _workerEtaPin(String eta, String initial) {
    return Column(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.success, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              eta,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customerLocationDot() {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF4AA9F7), width: 4),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _mapLocateButton() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Icon(Icons.my_location_rounded, color: AppTheme.textPrimary),
    );
  }

  Widget _buildElapsedTimer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.textMuted.withValues(
                    alpha: 0.45 + (_pulseController.value * 0.35),
                  ),
                  width: 2,
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          '$_elapsedTime sec',
          style: GoogleFonts.outfit(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentBookingCard(Booking booking) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF3F4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppTheme.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.home_repair_service_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.serviceName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${booking.customerLocationDisplay} • Rs ${booking.price.toInt()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.textPrimary),
        ],
      ),
    );
  }

  Widget _buildMatchingSteps(BookingProvider bp) {
    return Column(
      children: [
        _matchingStep(
          icon: Icons.travel_explore_rounded,
          label: 'Matching Nearby Pros',
          active: true,
          done: true,
        ),
        _matchingStep(
          icon: Icons.notifications_active_rounded,
          label: bp.isSocketConnected
              ? 'Sending Push Requests'
              : 'Reconnecting Push Requests',
          active: true,
          done: bp.isSocketConnected,
        ),
        _matchingStep(
          icon: Icons.assignment_turned_in_rounded,
          label: 'First Accepts Gets Job',
          active: false,
          done: false,
        ),
      ],
    );
  }

  Widget _matchingStep({
    required IconData icon,
    required String label,
    required bool active,
    required bool done,
  }) {
    final color = done || active ? AppTheme.success : AppTheme.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: color.withValues(alpha: done || active ? 1 : 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done || active ? Colors.white : AppTheme.textMuted,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: active || done
                    ? AppTheme.textPrimary
                    : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiryStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.26)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: AppTheme.warning, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Live matching until confirmed • Expires in $_formattedTime',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmedView(BookingProvider bp) {
    final provider = bp.confirmedProvider;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.success,
                        AppTheme.success.withValues(alpha: 0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.success.withValues(alpha: 0.4),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          Text(
            'Provider Found!',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A professional has accepted your booking',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Provider card
          if (provider != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.success.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        (provider['name'] as String? ?? 'P')[0].toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    provider['name'] ?? 'Provider',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your professional is on the way',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 40),

          // Track Provider button
          GradientButton(
            text: 'Track Provider',
            icon: Icons.location_on_rounded,
            onPressed: () {
              final bookingId = bp.instantBooking?.id ?? bp.trackingBookingId;
              if (bookingId != null) {
                Navigator.pushNamed(
                  context,
                  '/live-tracking',
                  arguments: bookingId,
                );
              }
            },
          ),
          const SizedBox(height: 12),
          GradientButton(
            text: 'View My Bookings',
            icon: Icons.list_alt_rounded,
            onPressed: () {
              bp.resetInstantBooking();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/bookings',
                (route) => route.settings.name == '/home',
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Expired View ────────────────────────────────────
  Widget _buildExpiredView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppTheme.error.withValues(alpha: 0.1),
                    border: Border.all(
                      color: AppTheme.error.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.timer_off_rounded,
                    color: AppTheme.error,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          Text(
            'Request Expired',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No professionals were available at this time.\nPlease try again or book for a later time.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          GradientButton(
            text: 'Try Again',
            icon: Icons.refresh_rounded,
            onPressed: () {
              context.read<BookingProvider>().resetInstantBooking();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              context.read<BookingProvider>().resetInstantBooking();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            },
            child: Text(
              'Back to Home',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0xFFEAF1EF);
    final park = Paint()..color = const Color(0xFFDDEFE4);
    final water = Paint()..color = const Color(0xFFD4EAF7);
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final minorRoad = Paint()
      ..color = const Color(0xFFB9C9D2).withValues(alpha: 0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Offset.zero & size, land);
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.08, 82, size.width * 0.34, 62),
      park,
    );
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.55, 104, size.width * 0.32, 76),
      water,
    );

    final roads = [
      [
        Offset(-24, 118),
        Offset(size.width * 0.35, 150),
        Offset(size.width + 24, 112),
      ],
      [
        Offset(18, 280),
        Offset(size.width * 0.46, 206),
        Offset(size.width + 18, 238),
      ],
      [
        Offset(size.width * 0.2, 54),
        Offset(size.width * 0.32, 198),
        Offset(size.width * 0.42, 340),
      ],
      [
        Offset(size.width * 0.76, 54),
        Offset(size.width * 0.66, 200),
        Offset(size.width * 0.58, 340),
      ],
    ];

    for (final roadPoints in roads) {
      final path = Path()..moveTo(roadPoints[0].dx, roadPoints[0].dy);
      path.quadraticBezierTo(
        roadPoints[1].dx,
        roadPoints[1].dy,
        roadPoints[2].dx,
        roadPoints[2].dy,
      );
      canvas.drawPath(path, road);
    }

    for (var i = 0; i < 8; i++) {
      final y = 76.0 + (i * 31);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y + (i.isEven ? 20 : -18)),
        minorRoad,
      );
    }

    for (var i = 0; i < 7; i++) {
      final x = 22.0 + (i * 58);
      canvas.drawLine(
        Offset(x, 54),
        Offset(x + (i.isEven ? 22 : -16), size.height),
        minorRoad,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MatchingPulsePainter extends CustomPainter {
  final double pulse;

  _MatchingPulsePainter(this.pulse);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, 193);
    final fill = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    final outerRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(center, 104 * pulse, fill);
    canvas.drawCircle(center, 72 * pulse, ring);
    canvas.drawCircle(center, 118 * pulse, outerRing);
  }

  @override
  bool shouldRepaint(covariant _MatchingPulsePainter oldDelegate) {
    return oldDelegate.pulse != pulse;
  }
}
