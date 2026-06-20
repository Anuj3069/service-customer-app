import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/service.dart';
import '../providers/service_provider.dart' as sp;

class MonthServicesScreen extends StatelessWidget {
  const MonthServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<sp.ServiceProvider>(
      builder: (context, serviceProvider, _) {
        final monthServices = serviceProvider.serviceCategories
            .expand((cat) => cat.services)
            .where((s) => s.allowMonthBooking)
            .toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6FB),
          body: Column(
            children: [
              _buildHeader(context, monthServices.length),
              if (monthServices.isEmpty)
                Expanded(child: _buildEmpty())
              else
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    itemCount: monthServices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) =>
                        _ServiceCard(service: monthServices[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, int count) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 10,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Book for Month',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$count service${count != 1 ? 's' : ''} available',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 42, color: AppTheme.primary),
          ),
          const SizedBox(height: 18),
          Text(
            'No monthly services yet',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin will enable services for\nmonthly booking soon.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Service service;
  const _ServiceCard({required this.service});

  IconData _icon(String name) {
    final n = name.toLowerCase();
    if (n.contains('plumbing')) return Icons.plumbing_rounded;
    if (n.contains('cleaning')) return Icons.cleaning_services_rounded;
    if (n.contains('electric')) return Icons.electrical_services_rounded;
    if (n.contains('paint')) return Icons.format_paint_rounded;
    if (n.contains('handyman')) return Icons.handyman_rounded;
    return Icons.home_repair_service_rounded;
  }

  Color _iconColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('plumbing')) return const Color(0xFF7B3FE4);
    if (n.contains('cleaning')) return const Color(0xFF20A852);
    if (n.contains('electric')) return const Color(0xFF2F80ED);
    if (n.contains('paint')) return const Color(0xFFFF6B2C);
    if (n.contains('handyman')) return const Color(0xFFFF5722);
    return AppTheme.primary;
  }

  Color _iconBg(String name) {
    final n = name.toLowerCase();
    if (n.contains('plumbing')) return const Color(0xFFF3EEFF);
    if (n.contains('cleaning')) return const Color(0xFFEFFBF3);
    if (n.contains('electric')) return const Color(0xFFF0F5FF);
    if (n.contains('paint')) return const Color(0xFFFFF2E8);
    if (n.contains('handyman')) return const Color(0xFFFFF1E9);
    return const Color(0xFFF1F6FF);
  }

  @override
  Widget build(BuildContext context) {
    final halfDay = service.basePrice.toInt();
    final fullDay = (service.basePrice * 16 / 9).round();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.pushNamed(
            context,
            '/month-booking',
            arguments: service,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _iconBg(service.name),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(_icon(service.name),
                          color: _iconColor(service.name), size: 30),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            service.name,
                            style: GoogleFonts.outfit(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            service.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE8ECF4)),
                  ),
                  child: Row(
                    children: [
                      _PriceChip(
                        label: 'Half Day',
                        sub: '9 hrs / day',
                        price: '₹$halfDay',
                      ),
                      const SizedBox(width: 1),
                      Container(
                          width: 1,
                          height: 36,
                          color: const Color(0xFFE8ECF4)),
                      const SizedBox(width: 1),
                      _PriceChip(
                        label: 'Full Day',
                        sub: '16 hrs / day',
                        price: '₹$fullDay',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _InfoChip(
                        icon: Icons.today_rounded, label: 'Mon – Sat'),
                    const SizedBox(width: 8),
                    _InfoChip(
                        icon: Icons.schedule_rounded,
                        label: '${service.duration} min session'),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      '/month-booking',
                      arguments: service,
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(
                      'Book for Month',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3730A3),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String sub;
  final String price;
  const _PriceChip(
      {required this.label, required this.sub, required this.price});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            price,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
