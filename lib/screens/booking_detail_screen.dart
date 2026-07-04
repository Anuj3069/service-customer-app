import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../services/booking_api_service.dart';
import '../utils/cancellation_reason_helper.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/gradient_button.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _refreshing = false;
  bool _canceling = false;

  BookingProvider? _bookingProvider;
  Timer? _pollTimer;

  // OTP state
  String? _otp;
  bool _otpLoading = false;
  bool _otpVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isFirstLoad = _booking == null;
    // Only seed from route args the very first time
    _booking ??= ModalRoute.of(context)!.settings.arguments as Booking;

    if (isFirstLoad) {
      _bookingProvider = context.read<BookingProvider>();
      _bookingProvider!.addListener(_onProviderChanged);
      // Populate the provider's selectedBooking immediately so socket
      // events (booking-accepted/rejected/completed) that arrive while
      // this screen is open know to refresh it.
      _refreshBooking();
      _startPolling();
    }
  }

  @override
  void didUpdateWidget(covariant BookingDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshBooking();
  }

  @override
  void dispose() {
    _bookingProvider?.removeListener(_onProviderChanged);
    _pollTimer?.cancel();
    super.dispose();
  }

  /// Reacts to BookingProvider.notifyListeners() (fired on booking-accepted /
  /// booking-rejected / booking-completed / booking-paid socket events) so
  /// this screen doesn't stay stuck showing stale status + Cancel button.
  void _onProviderChanged() {
    final fresh = _bookingProvider?.selectedBooking;
    if (fresh != null &&
        _booking != null &&
        fresh.id == _booking!.id &&
        fresh.status != _booking!.status) {
      setState(() => _booking = fresh);
    }
  }

  /// Fallback in case the socket event is missed (app backgrounded,
  /// reconnect race, etc.) - poll while the booking is still awaiting
  /// a worker's response.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      final booking = _booking;
      if (!mounted || booking == null) return;
      if (booking.isPending || booking.isRequested) {
        _refreshBooking();
      } else {
        _pollTimer?.cancel();
      }
    });
  }

  /// Re-fetch the booking every time this screen comes back into focus
  /// (e.g. after returning from Live Tracking or any other sub-screen).
  Future<void> _refreshBooking() async {
    if (_booking == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final bp = context.read<BookingProvider>();
      await bp.fetchBookingById(_booking!.id);
      final fresh = bp.selectedBooking;
      if (fresh != null && mounted) {
        setState(() => _booking = fresh);
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  void _openTracking(Booking booking) {
    context.read<BookingProvider>().startTrackingBooking(booking);
    Navigator.pushNamed(context, '/live-tracking', arguments: booking.id).then((
      _,
    ) {
      // Re-fetch when returning from the tracking screen
      _refreshBooking();
    });
  }

  Future<void> _revealOtp() async {
    if (_otp != null) {
      setState(() => _otpVisible = !_otpVisible);
      return;
    }
    if (_booking == null) return;
    setState(() => _otpLoading = true);
    try {
      final otp = await BookingApiService().getCompletionOtp(_booking!.id);
      if (mounted) {
        setState(() {
          _otp = otp;
          _otpVisible = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch OTP: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  Future<void> _cancelBooking(Booking booking) async {
    final reason = await showCancellationReasonPicker(context);

    if (reason == null || !mounted) return;

    setState(() => _canceling = true);
    final bp = context.read<BookingProvider>();
    final success = await bp.cancelBooking(
      booking.id,
      cancellationReason: reason,
    );

    if (!mounted) return;
    setState(() => _canceling = false);

    if (success) {
      final fresh = bp.selectedBooking;
      if (fresh != null) {
        setState(() => _booking = fresh);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bp.error ?? 'Failed to cancel booking'),
          backgroundColor: AppTheme.error,
        ),
      );
      _refreshBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      'Booking Details',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    _refreshing
                        ? const SizedBox(
                            width: 48,
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _refreshBooking,
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppTheme.textPrimary,
                                size: 20,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.statusColor(
                                      booking.status,
                                    ).withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: AppTheme.statusColor(
                                    booking.status,
                                  ).withValues(alpha: 0.15),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 74,
                                  height: 74,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.statusColor(
                                      booking.status,
                                    ).withValues(alpha: 0.1),
                                  ),
                                  child: Icon(
                                    _statusIcon(booking.status),
                                    color: AppTheme.statusColor(booking.status),
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            StatusBadge(status: booking.status),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Service info
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Service Information',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _detailRow('Service', booking.serviceName),
                            _detailRow(
                              'Date',
                              booking.date?.split('T')[0] ?? 'Instant',
                            ),
                            _detailRow('Time Slot', booking.slot ?? 'Now'),
                            _detailRow('Price', '₹${booking.price.toInt()}'),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Payment Status',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: booking.paymentStatus == 'paid'
                                          ? AppTheme.success.withValues(
                                              alpha: 0.1,
                                            )
                                          : (booking.paymentStatus == 'pending'
                                                ? AppTheme.warning.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : AppTheme.error.withValues(
                                                    alpha: 0.1,
                                                  )),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      booking.paymentStatus.toUpperCase(),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: booking.paymentStatus == 'paid'
                                            ? AppTheme.success
                                            : (booking.paymentStatus ==
                                                      'pending'
                                                  ? AppTheme.warning
                                                  : AppTheme.error),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Timeline
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Timeline',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _timelineItem(
                              'Booked',
                              booking.createdAt,
                              true,
                              isFirst: true,
                            ),
                            if (booking.acceptedAt != null)
                              _timelineItem(
                                'Accepted',
                                booking.acceptedAt!,
                                true,
                              ),
                            if (booking.completedAt != null)
                              _timelineItem(
                                'Completed',
                                booking.completedAt!,
                                true,
                                isLast: true,
                              ),
                            if (booking.rejectedAt != null)
                              _timelineItem(
                                'Rejected',
                                booking.rejectedAt!,
                                true,
                                isLast: true,
                                isError: true,
                              ),
                            if (booking.cancelledAt != null)
                              _timelineItem(
                                'Cancelled',
                                booking.cancelledAt!,
                                true,
                                isLast: true,
                                isError: true,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Track Provider button for accepted bookings ──
                      if (booking.canCancel) ...[
                        GradientButton(
                          text: 'Cancel Booking',
                          icon: Icons.cancel_rounded,
                          isLoading: _canceling,
                          gradient: const LinearGradient(
                            colors: [AppTheme.error, Color(0xFFC62828)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onPressed: _canceling
                              ? null
                              : () => _cancelBooking(booking),
                        ),
                        const SizedBox(height: 16),
                      ],

                      if (booking.status == 'accepted') ...[
                        // Worker location status chip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: booking.workerLocationCoordinates != null
                                ? AppTheme.success.withValues(alpha: 0.1)
                                : AppTheme.textMuted.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: booking.workerLocationCoordinates != null
                                  ? AppTheme.success.withValues(alpha: 0.3)
                                  : AppTheme.textMuted.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      booking.workerLocationCoordinates != null
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                booking.workerLocationCoordinates != null
                                    ? 'Provider location is available'
                                    : 'Waiting for provider location…',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      booking.workerLocationCoordinates != null
                                      ? AppTheme.success
                                      : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Track Provider',
                          icon: Icons.location_on_rounded,
                          onPressed: () => _openTracking(booking),
                        ),
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Chat with Provider',
                          icon: Icons.chat_bubble_rounded,
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/chat',
                              arguments: booking,
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // ── Completion OTP Card ──
                        GlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.lock_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Job Completion OTP',
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Share this code with the provider when work is done',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: AppTheme.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _otpLoading
                                      ? const SizedBox(
                                          height: 44,
                                          child: Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTheme.primary,
                                              ),
                                            ),
                                          ),
                                        )
                                      : _otpVisible &&
                                            _otp != null &&
                                            _otp!.isNotEmpty
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: _otp!.split('').map((
                                            digit,
                                          ) {
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                right: 8,
                                              ),
                                              width: 42,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                gradient:
                                                    AppTheme.primaryGradient,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppTheme.primary
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Center(
                                                child: Text(
                                                  digit,
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w900,
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
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.textMuted,
                                            letterSpacing: 6,
                                          ),
                                        ),
                                  GestureDetector(
                                    onTap: _revealOtp,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.2,
                                          ),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Review / Payment button for completed bookings
                      if (booking.status == 'completed') ...[
                        if (booking.paymentStatus == 'paid') ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppTheme.success,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Payment completed successfully!',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradientButton(
                            text: 'Write a Review',
                            icon: Icons.star_rounded,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/review',
                                arguments: booking,
                              );
                            },
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: AppTheme.warning.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppTheme.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.payment_rounded,
                                  color: AppTheme.warning,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    booking.paymentStatus == 'pending'
                                        ? 'Payment is pending verification...'
                                        : 'Paid in cash? Your provider will confirm receipt. Or pay online below.',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GradientButton(
                            text: 'Pay Booking (₹${booking.price.toInt()})',
                            icon: Icons.payment_rounded,
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/payment',
                                arguments: booking,
                              ).then((_) {
                                _refreshBooking();
                              });
                            },
                          ),
                        ],
                      ],
                      if (['accepted', 'completed', 'cancelled']
                          .contains(booking.status)) ...[
                        const SizedBox(height: 12),
                        GradientButton(
                          text: 'Contact Support',
                          icon: Icons.support_agent_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF4A47C1)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/support-chat',
                              arguments: {'bookingId': booking.id},
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'requested':
        return Icons.hourglass_top_rounded;
      case 'accepted':
        return Icons.check_circle_rounded;
      case 'completed':
        return Icons.task_alt_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'cancelled':
        return Icons.block_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelineItem(
    String title,
    String dateStr,
    bool isCompleted, {
    bool isFirst = false,
    bool isLast = false,
    bool isError = false,
  }) {
    final color = isError ? AppTheme.error : AppTheme.success;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.white,
                border: Border.all(
                  color: isCompleted
                      ? color
                      : AppTheme.textMuted.withValues(alpha: 0.4),
                  width: 2,
                ),
                boxShadow: isCompleted
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: isCompleted
                  ? Center(
                      child: Icon(
                        isError ? Icons.close : Icons.check,
                        size: 10,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            if (!isLast)
              SizedBox(
                width: 2,
                height: 32,
                child: CustomPaint(
                  painter: DottedLinePainter(
                    color: isCompleted
                        ? color.withValues(alpha: 0.6)
                        : AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr.split('T')[0],
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textMuted),
            ),
            if (!isLast) const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}

class DottedLinePainter extends CustomPainter {
  final Color color;

  DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startY = 0;
    while (startY < size.height) {
      canvas.drawCircle(Offset(size.width / 2, startY), 1.2, paint);
      startY += 6;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
