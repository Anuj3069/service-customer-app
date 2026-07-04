import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../providers/address_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

class MatchResultScreen extends StatefulWidget {
  const MatchResultScreen({super.key});

  @override
  State<MatchResultScreen> createState() => _MatchResultScreenState();
}

class _MatchResultScreenState extends State<MatchResultScreen> {
  Future<void> _confirmBooking(BuildContext context) async {
    final bookingProvider = context.read<BookingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final success = await bookingProvider.createBooking(
      customerLocation: context.read<AddressProvider>().selectedAddress?.toCustomerLocation(),
    );

    if (!mounted) return;

    if (success) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: Color(0xFF00C853),
        ),
      );
      navigator.pushReplacementNamed(
        '/booking-detail',
        arguments: bookingProvider.selectedBooking,
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(bookingProvider.error ?? 'Failed to confirm booking'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Consumer<BookingProvider>(
            builder: (context, bookingProvider, _) {
              final match = bookingProvider.matchResult;
              if (match == null) {
                return const Center(
                  child: Text(
                    'No match data',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                );
              }

              return Column(
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
                            onPressed: () {
                              bookingProvider.clearMatchResult();
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                        Text(
                          'Provider Found',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(
                          width: 48,
                        ), // visually balance back arrow
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          // Success icon
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF00E676), Color(0xFF00C853)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.success.withValues(
                                    alpha: 0.4,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 38,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Perfect Match!',
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We found the best provider for you',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Provider card
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Center(
                                    child: Text(
                                      match.provider.name[0].toUpperCase(),
                                      style: GoogleFonts.outfit(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  match.provider.name,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Color(0xFFFFD700),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      match.provider.rating.toStringAsFixed(1),
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.work_rounded,
                                      color: AppTheme.textMuted,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${match.provider.totalJobs} jobs',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    if (match.provider.isVerified) ...[
                                      const SizedBox(width: 12),
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: AppTheme.accent,
                                        size: 20,
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Booking summary
                          GlassCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Summary',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _summaryRow('Service', match.service.name),
                                _summaryRow('Date', match.date.split('T')[0]),
                                _summaryRow('Time Slot', match.slot),
                                _summaryRow(
                                  'Duration',
                                  '${match.estimatedDuration} min',
                                ),
                                const Divider(
                                  color: AppTheme.textMuted,
                                  height: 32,
                                ),
                                _summaryRow(
                                  'Subtotal',
                                  '₹${match.price.toInt()}',
                                ),
                                const Divider(
                                  color: AppTheme.textMuted,
                                  height: 32,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: GoogleFonts.outfit(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '₹${match.price.toInt()}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          GradientButton(
                            text: 'Confirm Booking',
                            icon: Icons.check_circle_rounded,
                            isLoading: bookingProvider.isLoading,
                            onPressed: () => _confirmBooking(context),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              bookingProvider.clearMatchResult();
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
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
}
