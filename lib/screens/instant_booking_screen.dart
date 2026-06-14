import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
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
  int _secondsRemaining = 300; // Default 5 minutes, synced with Redis TTL
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
    super.dispose();
  }

  String get _formattedTime {
    final min = _secondsRemaining ~/ 60;
    final sec = _secondsRemaining % 60;
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
        return _buildSearchingView(bp);
    }
  }

  // ── Searching View ──────────────────────────────────
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
