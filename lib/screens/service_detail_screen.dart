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

  Widget _buildVectorIllustration(String name) {
    final cleanName = name.toLowerCase();
    CustomPainter painter;
    if (cleanName.contains('tap') || cleanName.contains('faucet') || cleanName.contains('installation')) {
      painter = FaucetPainter();
    } else if (cleanName.contains('pipe') || cleanName.contains('leak') || cleanName.contains('repair')) {
      painter = PipesPainter();
    } else {
      painter = WrenchPainter();
    }
    return SizedBox(
      width: 90,
      height: 90,
      child: CustomPaint(painter: painter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as Service;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Custom styled app bar
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
                      'Service Details',
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
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Illustration Card (Row based for right-side custom illustration)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service.name,
                                    style: GoogleFonts.outfit(
                                      fontSize: 24,
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
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      _infoChip(
                                        Icons.currency_rupee_rounded,
                                        '₹${service.basePrice.toInt()}',
                                      ),
                                      const SizedBox(width: 10),
                                      _infoChip(
                                        Icons.access_time_rounded,
                                        '${service.duration} min',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Custom programmatically painted illustration
                            _buildVectorIllustration(service.name),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      _bookModeSelector(),
                      const SizedBox(height: 24),

                      if (_bookNow) ...[
                        _nowArrivalCard(service),
                        const SizedBox(height: 24),
                        _buildTrustRow(
                          badges: [
                            MapEntry('Verified Pros', Icons.verified_user_rounded),
                            MapEntry('Upfront Pricing', Icons.monetization_on_rounded),
                            MapEntry('24/7 Support', Icons.support_agent_rounded),
                          ],
                        ),
                        const SizedBox(height: 28),
                      ],

                      if (!_bookNow) ...[
                        Text(
                          'Select Date',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 82,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
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
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 65,
                                            margin: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? AppTheme.primaryGradient
                                                  : null,
                                              color: isSelected ? null : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              border: isSelected
                                                  ? null
                                                  : Border.all(
                                                      color: AppTheme.primary.withValues(alpha: 0.05),
                                                    ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.02),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  DateFormat('EEE').format(date),
                                                  style: GoogleFonts.inter(
                                                    fontSize: 12,
                                                    color: isSelected
                                                        ? Colors.white.withValues(alpha: 0.8)
                                                        : AppTheme.textMuted,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${date.day}',
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w800,
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
                                                        ? Colors.white.withValues(alpha: 0.8)
                                                        : AppTheme.textMuted,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Positioned(
                                              top: 0,
                                              right: 8,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.check_circle_rounded,
                                                  color: AppTheme.primary,
                                                  size: 14,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              height: 60,
                              width: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primary.withValues(alpha: 0.05),
                                ),
                              ),
                              child: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'Select Time Slot',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.8,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final slot = _timeSlots[index];
                            final isSelected = _selectedSlot == slot;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedSlot = slot),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF7FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primary : AppTheme.primary.withValues(alpha: 0.05),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        slot,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                          color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppTheme.primary,
                                          size: 16,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 30),
                        _buildTrustBanner(),
                        const SizedBox(height: 28),
                      ],

                      if (service.requiredSkills.isNotEmpty) ...[
                        Text(
                          'Required Skills',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
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
                                color: AppTheme.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.accent.withValues(alpha: 0.2),
                                ),
                              ),
                              child: Text(
                                skill,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 30),
                      ],

                      // Sleek Booking Buttons
                      Consumer<BookingProvider>(
                        builder: (context, bookingProvider, _) {
                          if (_bookNow) {
                            return GestureDetector(
                              onTap: bookingProvider.isLoading
                                  ? null
                                  : () => _requestInstantBooking(service),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: bookingProvider.isLoading
                                    ? const Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.flash_on_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Request Instant Service',
                                                style: GoogleFonts.outfit(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                'Get a pro at your doorstep in minutes',
                                                style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.white.withValues(alpha: 0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          } else {
                            return GradientButton(
                              text: 'Confirm Slot',
                              icon: Icons.check_circle_outline_rounded,
                              isLoading: bookingProvider.isLoading,
                              onPressed: (_selectedDate != null && _selectedSlot != null)
                                  ? () => _createDirectBooking(service)
                                  : null,
                            );
                          }
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
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeButton(
              icon: Icons.flash_on_rounded,
              label: 'Book Now',
              selected: _bookNow,
              onTap: () => setState(() => _bookNow = true),
            ),
          ),
          Expanded(
            child: _modeButton(
              icon: Icons.calendar_today_rounded,
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
              size: 18,
              color: selected ? Colors.white : AppTheme.textPrimary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 16,
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Estimated Arrival',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.access_time_filled_rounded,
                color: AppTheme.primary,
                size: 32,
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat('hh:mm a').format(DateTime.now()),
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  'Job Duration: ${service.duration} mins',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Will finish around ${DateFormat('hh:mm a').format(endAt)}',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustRow({required List<MapEntry<String, IconData>> badges}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: badges.map((badge) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              badge.value,
              size: 16,
              color: AppTheme.primary,
            ),
            const SizedBox(width: 5),
            Text(
              badge.key,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTrustBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Trusted & Verified Professionals only.',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bgCardLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
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

  Future<void> _createDirectBooking(Service service) async {
    final bookingProvider = context.read<BookingProvider>();
    final bookingDate = _dateWithSlotStart(_selectedDate!, _selectedSlot!);

    // Step 1: Find the best available provider for this date & slot
    final matchFound = await bookingProvider.findMatch(
      serviceId: service.id,
      date: bookingDate.toIso8601String(),
      slot: _selectedSlot!,
    );

    if (!mounted) return;

    if (!matchFound) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bookingProvider.error ?? 'No providers available for this slot.',
          ),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    // Step 2: Confirm booking with the matched provider
    final success = await bookingProvider.createBooking();

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

class FaucetPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.fill;
    final accentPaint = Paint()
      ..color = const Color(0xFFCFD8DC)
      ..style = PaintingStyle.fill;
    final handlePaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    final waterPaint = Paint()
      ..color = const Color(0x992196F3)
      ..style = PaintingStyle.fill;

    // Draw faucet pipe curve
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.6)
      ..lineTo(size.width * 0.5, size.height * 0.6)
      ..cubicTo(size.width * 0.7, size.height * 0.6, size.width * 0.7, size.height * 0.2, size.width * 0.5, size.height * 0.2)
      ..lineTo(size.width * 0.45, size.height * 0.2)
      ..lineTo(size.width * 0.45, size.height * 0.3)
      ..lineTo(size.width * 0.5, size.height * 0.3)
      ..cubicTo(size.width * 0.6, size.height * 0.3, size.width * 0.6, size.height * 0.5, size.width * 0.5, size.height * 0.5)
      ..lineTo(size.width * 0.1, size.height * 0.5)
      ..close();
    canvas.drawPath(path, bodyPaint);

    // Draw faucet mouth/nozzle
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.3, size.width * 0.08, size.height * 0.05),
      accentPaint,
    );

    // Draw handle knob
    canvas.drawCircle(Offset(size.width * 0.35, size.height * 0.55), 6, handlePaint);

    // Draw water droplets
    final dropPath = Path()
      ..moveTo(size.width * 0.46, size.height * 0.42)
      ..lineTo(size.width * 0.44, size.height * 0.48)
      ..arcToPoint(Offset(size.width * 0.48, size.height * 0.48), radius: const Radius.circular(2))
      ..close();
    canvas.drawPath(dropPath, waterPaint);

    final dropPath2 = Path()
      ..moveTo(size.width * 0.46, size.height * 0.54)
      ..lineTo(size.width * 0.44, size.height * 0.6)
      ..arcToPoint(Offset(size.width * 0.48, size.height * 0.6), radius: const Radius.circular(2))
      ..close();
    canvas.drawPath(dropPath2, waterPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PipesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pipePaint = Paint()
      ..color = const Color(0xFF78909C)
      ..style = PaintingStyle.fill;
    final jointPaint = Paint()
      ..color = const Color(0xFFB0BEC5)
      ..style = PaintingStyle.fill;
    final dropPaint = Paint()
      ..color = const Color(0xFF2196F3).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    // Horizontal pipe
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.4, size.width * 0.8, size.height * 0.16),
      pipePaint,
    );
    // Vertical pipe going down
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.5, size.height * 0.4, size.width * 0.16, size.height * 0.5),
      pipePaint,
    );

    // Pipe joints/collars
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.47, size.height * 0.37, size.width * 0.22, size.height * 0.08),
        const Radius.circular(3),
      ),
      jointPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.76, size.height * 0.38, size.width * 0.08, size.height * 0.2),
        const Radius.circular(3),
      ),
      jointPaint,
    );

    // Water droplet under joint
    final drop = Path()
      ..moveTo(size.width * 0.58, size.height * 0.48)
      ..lineTo(size.width * 0.55, size.height * 0.56)
      ..arcToPoint(Offset(size.width * 0.61, size.height * 0.56), radius: const Radius.circular(3))
      ..close();
    canvas.drawPath(drop, dropPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class WrenchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final metalPaint = Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.fill;
    final darkMetalPaint = Paint()
      ..color = const Color(0xFF607D8B)
      ..style = PaintingStyle.fill;

    // Draw wrench handle
    final handle = Path()
      ..moveTo(size.width * 0.2, size.height * 0.8)
      ..lineTo(size.width * 0.6, size.height * 0.4)
      ..lineTo(size.width * 0.7, size.height * 0.5)
      ..lineTo(size.width * 0.3, size.height * 0.9)
      ..close();
    canvas.drawPath(handle, metalPaint);

    // Draw wrench head
    canvas.drawCircle(Offset(size.width * 0.65, size.height * 0.45), 14, metalPaint);

    // Draw wrench head cutout
    final cutout = Path()
      ..moveTo(size.width * 0.58, size.height * 0.38)
      ..lineTo(size.width * 0.72, size.height * 0.52)
      ..lineTo(size.width * 0.78, size.height * 0.46)
      ..lineTo(size.width * 0.64, size.height * 0.32)
      ..close();
    canvas.drawPath(cutout, darkMetalPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
