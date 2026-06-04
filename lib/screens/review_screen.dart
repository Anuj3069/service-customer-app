import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/booking.dart';
import '../providers/booking_provider.dart';
import '../widgets/gradient_button.dart';
import '../widgets/glass_card.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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
                      'Write Review',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 48), // visually balance back arrow
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'How was the service?',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        booking.serviceName,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Stars
                      GlassCard(
                        padding: const EdgeInsets.symmetric(
                            vertical: 28, horizontal: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: List.generate(5, (index) {
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _rating = index + 1),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(
                                      index < _rating
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      size: 44,
                                      color: index < _rating
                                          ? const Color(0xFFFFD700)
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _ratingText(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Comment
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: TextField(
                          controller: _commentController,
                          maxLines: 5,
                          maxLength: 500,
                          style: GoogleFonts.inter(
                            color: AppTheme.textPrimary,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'Tell us about your experience (optional)',
                            hintStyle: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                            ),
                            border: InputBorder.none,
                            counterStyle: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, _) {
                          return GradientButton(
                            text: 'Submit Review',
                            icon: Icons.send_rounded,
                            isLoading: bookingProvider.isLoading,
                            onPressed: _rating > 0
                                ? () =>
                                    _submitReview(context, booking)
                                : null,
                          );
                        },
                      ),
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

  String _ratingText() {
    switch (_rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent! 🤩';
      default:
        return 'Tap a star to rate';
    }
  }

  Future<void> _submitReview(BuildContext context, Booking booking) async {
    final bookingProvider = context.read<BookingProvider>();
    final success = await bookingProvider.submitReview(
      bookingId: booking.id,
      rating: _rating,
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
    );

    if (!context.mounted) return;

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⭐ Review submitted! Thank you!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(bookingProvider.error ?? 'Failed to submit review'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
