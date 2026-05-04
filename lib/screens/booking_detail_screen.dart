import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../widgets/glass_card.dart';
import '../widgets/status_badge.dart';
import '../widgets/gradient_button.dart';

class BookingDetailScreen extends StatelessWidget {
  const BookingDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)!.settings.arguments as Booking;

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
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
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
