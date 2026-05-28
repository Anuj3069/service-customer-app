import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class PaymentResultScreen extends StatefulWidget {
  const PaymentResultScreen({super.key});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  Booking? _booking;
  bool _success = false;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Parse arguments
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _booking = args['booking'] as Booking?;
    _success = args['success'] as bool? ?? false;
    _message = args['message'] as String? ?? '';

    final booking = _booking;
    if (booking == null) {
      return const Scaffold(
        body: Center(child: Text('Invalid transaction state.')),
      );
    }

    final statusColor = _success ? AppTheme.success : AppTheme.error;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Animated Status Icon
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withValues(alpha: 0.1),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.25),
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.15),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                        color: statusColor,
                        size: 60,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Animated Result Headline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    _success ? 'Payment Successful' : 'Payment Failed',
                    style: GoogleFonts.outfit(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Animated Result Description
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _message,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Animated Transaction Info Card
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: GlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transaction Details',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _detailRow('Service', booking.serviceName),
                        _detailRow('Provider', booking.providerName),
                        _detailRow('Amount Paid', '₹${booking.price.toInt()}'),
                        _detailRow('Booking ID', '#${booking.id.substring(booking.id.length - 8).toUpperCase()}'),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),

                // Action Buttons
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      if (!_success) ...[
                        GradientButton(
                          text: 'Retry Payment',
                          icon: Icons.replay_rounded,
                          onPressed: () {
                            // Go back to PaymentScreen and restart payment flow
                            Navigator.pop(context);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      GradientButton(
                        text: _success ? 'View Booking Details' : 'Back to Booking',
                        icon: Icons.event_note_rounded,
                        // Make sure we pop/navigate back correctly
                        onPressed: () {
                          // Pop back or navigate back to the detail screen.
                          // Pop back all checkout/result screens and refresh booking details
                          Navigator.popUntil(context, ModalRoute.withName('/booking-detail'));
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
