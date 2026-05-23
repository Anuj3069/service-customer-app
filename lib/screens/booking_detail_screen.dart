import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../services/booking_api_service.dart';
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

  // OTP state
  String? _otp;
  bool _otpLoading = false;
  bool _otpVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only seed from route args the very first time
    _booking ??=
        ModalRoute.of(context)!.settings.arguments as Booking;
  }

  @override
  void didUpdateWidget(covariant BookingDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshBooking();
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
    Navigator.pushNamed(
      context,
      '/live-tracking',
      arguments: booking.id,
    ).then((_) {
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
          SnackBar(content: Text('Could not fetch OTP: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _otpLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        'Booking Details',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    // Refresh indicator
                    if (_refreshing)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primary,
                        ),
                      )
                    else
                      IconButton(
                        onPressed: _refreshBooking,
                        icon: const Icon(Icons.refresh_rounded,
                            color: AppTheme.textMuted),
                        tooltip: 'Refresh',
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppTheme.statusColor(booking.status)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Icon(
                                _statusIcon(booking.status),
                                color:
                                    AppTheme.statusColor(booking.status),
                                size: 40,
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
                                'Date', booking.date?.split('T')[0] ?? 'Instant'),
                            _detailRow('Time Slot', booking.slot ?? 'Now'),
                            _detailRow(
                                'Price', '₹${booking.price.toInt()}'),
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
                      if (booking.status == 'accepted') ...[
                        // Worker location status chip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
                                  color: booking.workerLocationCoordinates != null
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
                                  color: booking.workerLocationCoordinates != null
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
                                    child: const Icon(Icons.lock_rounded,
                                        color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                      : _otpVisible && _otp != null && _otp!.isNotEmpty
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: _otp!.split('').map((digit) {
                                                return Container(
                                                  margin: const EdgeInsets.only(right: 8),
                                                  width: 42,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    gradient: AppTheme.primaryGradient,
                                                    borderRadius: BorderRadius.circular(12),
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
                                                      style: GoogleFonts.jetBrainsMono(
                                                        fontSize: 24,
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
                                          horizontal: 18, vertical: 10),
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
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Review button for completed bookings
                      if (booking.status == 'completed')
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
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textMuted,
            ),
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
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : AppTheme.textMuted,
              ),
              child: isCompleted
                  ? Icon(
                      isError ? Icons.close : Icons.check,
                      size: 10,
                      color: Colors.white,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppTheme.textMuted.withValues(alpha: 0.3),
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
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              dateStr.split('T')[0],
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppTheme.textMuted,
              ),
            ),
            if (!isLast) const SizedBox(height: 16),
          ],
        ),
      ],
    );
  }
}
