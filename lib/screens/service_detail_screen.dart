import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/service.dart';
import '../providers/booking_provider.dart';
import '../widgets/gradient_button.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({super.key});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  DateTime? _selectedDate;
  String? _selectedSlot;

  final List<String> _timeSlots = [
    '09:00-10:00',
    '10:00-11:00',
    '11:00-12:00',
    '12:00-13:00',
    '14:00-15:00',
    '15:00-16:00',
    '16:00-17:00',
    '17:00-18:00',
  ];

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as Service;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
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
                        'Service Details',
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service hero card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF6C63FF),
                              Color(0xFF3F37C9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppTheme.primary.withValues(alpha: 0.4),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.home_repair_service_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              service.name,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service.description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color:
                                    Colors.white.withValues(alpha: 0.85),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _infoChip(
                                    Icons.currency_rupee_rounded,
                                    '₹${service.basePrice.toInt()}'),
                                const SizedBox(width: 12),
                                _infoChip(Icons.access_time_rounded,
                                    '${service.duration} min'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Date picker
                      Text(
                        'Select Date',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 85,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 14,
                          itemBuilder: (context, index) {
                            final date =
                                DateTime.now().add(Duration(days: index + 1));
                            final isSelected =
                                _selectedDate?.day == date.day &&
                                    _selectedDate?.month == date.month;

                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedDate = date),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 200),
                                width: 65,
                                margin:
                                    const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: isSelected
                                      ? null
                                      : AppTheme.surface,
                                  borderRadius:
                                      BorderRadius.circular(16),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: AppTheme.textMuted
                                              .withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      DateFormat('EEE').format(date),
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${date.day}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('MMM').format(date),
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Time slot picker
                      Text(
                        'Select Time Slot',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _timeSlots.map((slot) {
                          final isSelected = _selectedSlot == slot;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedSlot = slot),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: isSelected
                                    ? AppTheme.primaryGradient
                                    : null,
                                color: isSelected
                                    ? null
                                    : AppTheme.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: AppTheme.textMuted
                                            .withValues(alpha: 0.2)),
                              ),
                              child: Text(
                                slot,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 36),

                      // Skills
                      if (service.requiredSkills.isNotEmpty) ...[
                        Text(
                          'Required Skills',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: service.requiredSkills.map((skill) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppTheme.accent
                                        .withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                skill,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 36),
                      ],

                      // Find Provider button
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, _) {
                          return GradientButton(
                            text: 'Find Provider',
                            icon: Icons.search_rounded,
                            isLoading: bookingProvider.isLoading,
                            onPressed:
                                (_selectedDate != null &&
                                        _selectedSlot != null)
                                    ? () => _findMatch(service)
                                    : null,
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

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findMatch(Service service) async {
    final bookingProvider = context.read<BookingProvider>();
    final dateStr = _selectedDate!.toIso8601String();

    final success = await bookingProvider.findMatch(
      serviceId: service.id,
      date: dateStr,
      slot: _selectedSlot!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, '/match-result');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.error ?? 'No provider available'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}
