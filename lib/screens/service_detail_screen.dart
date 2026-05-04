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
  static const String _defaultProviderId = '69e4cb45a84793d1c987d25d';
  bool _bookNow = true;
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.textPrimary,
                      ),
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
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.76),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.10),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
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
                                gradient: AppTheme.primaryGradient,
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
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service.description,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _infoChip(
                                  Icons.currency_rupee_rounded,
                                  '₹${service.basePrice.toInt()}',
                                ),
                                const SizedBox(width: 12),
                                _infoChip(
                                  Icons.access_time_rounded,
                                  '${service.duration} min',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      _bookModeSelector(),
                      const SizedBox(height: 28),

                      if (_bookNow) ...[
                        _nowArrivalCard(service),
                        const SizedBox(height: 28),
                      ],

                      if (!_bookNow) ...[
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
                              final date = DateTime.now().add(
                                Duration(days: index + 1),
                              );
                              final isSelected =
                                  _selectedDate?.day == date.day &&
                                  _selectedDate?.month == date.month;

                              return GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedDate = date),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 65,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    gradient: isSelected
                                        ? AppTheme.primaryGradient
                                        : null,
                                    color: isSelected ? null : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: AppTheme.textMuted
                                                .withValues(alpha: 0.2),
                                          ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        DateFormat('EEE').format(date),
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: isSelected
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
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
                                              ? Colors.white.withValues(
                                                  alpha: 0.8,
                                                )
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
                              onTap: () => setState(() => _selectedSlot = slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  gradient: isSelected
                                      ? AppTheme.primaryGradient
                                      : null,
                                  color: isSelected ? null : AppTheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: isSelected
                                      ? null
                                      : Border.all(
                                          color: AppTheme.textMuted.withValues(
                                            alpha: 0.2,
                                          ),
                                        ),
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
                      ],

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
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.3),
                                ),
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

                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, _) {
                          return GradientButton(
                            text: _bookNow
                                ? 'Request Instant Service'
                                : 'Confirm Slot',
                            icon: _bookNow
                                ? Icons.flash_on_rounded
                                : Icons.search_rounded,
                            isLoading: bookingProvider.isLoading,
                            onPressed:
                                (_bookNow ||
                                    (_selectedDate != null &&
                                        _selectedSlot != null))
                                ? () => _bookNow
                                      ? _requestInstantBooking(service)
                                      : _createDirectBooking(service)
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

  Widget _bookModeSelector() {
    return Container(
      height: 62,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(31),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              icon: Icons.calendar_month_rounded,
              label: 'Book Now',
              selected: _bookNow,
              onTap: () => setState(() => _bookNow = true),
            ),
          ),
          Expanded(
            child: _modeButton(
              icon: Icons.event_available_rounded,
              label: 'Book Later',
              selected: !_bookNow,
              onTap: () => setState(() => _bookNow = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 21,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nowArrivalCard(Service service) {
    final endAt = DateTime.now().add(Duration(minutes: service.duration));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Text(
            'Service at',
            style: GoogleFonts.inter(fontSize: 22, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: GoogleFonts.outfit(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const Divider(height: 36),
          Text.rich(
            TextSpan(
              text: 'Service end at ',
              children: [
                TextSpan(
                  text: '${service.duration} min',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            style: GoogleFonts.inter(fontSize: 18, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            '${DateFormat('HH:mm').format(endAt)} IST service end time',
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestInstantBooking(Service service) async {
    final bookingProvider = context.read<BookingProvider>();

    final success = await bookingProvider.createInstantBooking(
      serviceId: service.id,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamed(context, '/instant-booking');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.error ?? 'No providers available'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _findMatch(Service service) async {
    final bookingProvider = context.read<BookingProvider>();
    final dateStr = (_bookNow ? DateTime.now() : _selectedDate!)
        .toIso8601String();

    final success = await bookingProvider.findMatch(
      serviceId: service.id,
      date: dateStr,
      slot: _bookNow ? 'Now' : _selectedSlot!,
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

  Future<void> _createDirectBooking(Service service) async {
    final bookingProvider = context.read<BookingProvider>();
    final bookingDate = _dateWithSlotStart(_selectedDate!, _selectedSlot!);

    final success = await bookingProvider.createDirectBooking(
      providerId: _defaultProviderId,
      serviceId: service.id,
      date: bookingDate.toIso8601String(),
      slot: _selectedSlot!,
      price: service.basePrice,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bookings',
        (route) => route.settings.name == '/home',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(bookingProvider.error ?? 'Failed to create booking'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  DateTime _dateWithSlotStart(DateTime date, String slot) {
    final start = slot.split('-').first;
    final parts = start.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
