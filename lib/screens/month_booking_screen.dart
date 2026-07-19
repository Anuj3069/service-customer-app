import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/service.dart';
import '../providers/booking_provider.dart';
import '../providers/address_provider.dart';

class MonthBookingScreen extends StatefulWidget {
  const MonthBookingScreen({super.key});

  @override
  State<MonthBookingScreen> createState() => _MonthBookingScreenState();
}

class _MonthBookingScreenState extends State<MonthBookingScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 1);

  int _workingDays(DateTime start) {
    final last = DateTime(start.year, start.month + 1, 0);
    return last.difference(start).inDays + 1;
  }

  String _monthLabel(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[dt.month]} ${dt.year}';
  }

  void _changeMonth(int delta) {
    final now = DateTime.now();
    final earliest = DateTime(now.year, now.month + 1, 1);
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    if (next.isBefore(earliest)) return;
    setState(() => _selectedMonth = next);
  }

  Future<void> _confirmBooking(Service service) async {
    final ap = context.read<AddressProvider>();
    if (ap.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a service address first'),
        backgroundColor: AppTheme.warning,
      ));
      Navigator.pushNamed(context, '/address-search');
      return;
    }

    final bookingProvider = context.read<BookingProvider>();
    final success = await bookingProvider.createMonthBooking(
      serviceId: service.id,
      monthStart: _selectedMonth,
      customerLocation: ap.selectedAddress!.toCustomerLocation(),
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Month booking created! Waiting for provider confirmation.'),
        backgroundColor: AppTheme.success,
      ));
      Navigator.pushNamedAndRemoveUntil(context, '/bookings', (r) => r.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(bookingProvider.error ?? 'Failed to create month booking'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ModalRoute.of(context)!.settings.arguments as Service;
    final days = _workingDays(_selectedMonth);
    final daily = service.monthBasePrice ?? service.basePrice;
    final total = daily * days;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
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
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: AppTheme.textPrimary, size: 20),
                      ),
                    ),
                    Text(
                      'Book for Month',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 48),
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
                      // Service info card
                      _card(
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.build_rounded,
                                  color: AppTheme.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(service.name,
                                      style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.textPrimary)),
                                  Text('Base rate ₹${(service.monthBasePrice ?? service.basePrice).toInt()} / day',
                                      style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Month picker
                      Text('Select Month',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      _card(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _changeMonth(-1),
                              icon: const Icon(Icons.chevron_left_rounded,
                                  color: AppTheme.primary),
                            ),
                            Text(
                              _monthLabel(_selectedMonth),
                              style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary),
                            ),
                            IconButton(
                              onPressed: () => _changeMonth(1),
                              icon: const Icon(Icons.chevron_right_rounded,
                                  color: AppTheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Price summary
                      Text('Price Summary',
                          style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      const SizedBox(height: 12),
                      _card(
                        child: Column(
                          children: [
                            _priceRow('Working days', '$days days'),
                            _priceRow('Daily rate', '₹${daily.toInt()}'),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.textPrimary)),
                                Text('₹${total.toInt()}',
                                    style: GoogleFonts.outfit(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Address
                      Consumer<AddressProvider>(
                        builder: (context, ap, _) {
                          final addr = ap.selectedAddress;
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/address-search'),
                            child: _card(
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: addr != null
                                          ? AppTheme.primary.withValues(alpha: 0.08)
                                          : AppTheme.warning.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      addr != null
                                          ? Icons.location_on_rounded
                                          : Icons.add_location_alt_rounded,
                                      color: addr != null ? AppTheme.primary : AppTheme.warning,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: addr != null
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Service at',
                                                  style: GoogleFonts.inter(
                                                      fontSize: 11,
                                                      color: AppTheme.textMuted)),
                                              Text(addr.displayLabel,
                                                  style: GoogleFonts.outfit(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w700,
                                                      color: AppTheme.textPrimary)),
                                              Text(addr.shortAddress,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: GoogleFonts.inter(
                                                      fontSize: 12,
                                                      color: AppTheme.textSecondary)),
                                            ],
                                          )
                                        : Text('Tap to select service address',
                                            style: GoogleFonts.outfit(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.warning)),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: AppTheme.textMuted.withValues(alpha: 0.5)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 28),

                      // Confirm button
                      Consumer<BookingProvider>(
                        builder: (context, bp, _) => GestureDetector(
                          onTap: bp.isLoading ? null : () => _confirmBooking(service),
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
                            child: bp.isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2.5),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.calendar_month_rounded,
                                          color: Colors.white, size: 22),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('Confirm Month Booking',
                                              style: GoogleFonts.outfit(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white)),
                                          Text('₹${total.toInt()} · $days days',
                                              style: GoogleFonts.inter(
                                                  fontSize: 12,
                                                  color: Colors.white.withValues(alpha: 0.8))),
                                        ],
                                      ),
                                    ],
                                  ),
                          ),
                        ),
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _priceRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppTheme.textSecondary)),
          Text(value,
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }
}
