import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/booking_provider.dart';
import '../models/booking.dart';
import '../widgets/status_badge.dart';
import '../widgets/connection_banner.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['All', 'Pending', 'Accepted', 'Completed'];

  IconData _getCategoryIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) {
      return Icons.plumbing_rounded;
    }
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) {
      return Icons.cleaning_services_rounded;
    }
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) {
      return Icons.electrical_services_rounded;
    }
    if (name.contains('paint') || name.contains('wall')) {
      return Icons.format_paint_rounded;
    }
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) {
      return Icons.handyman_rounded;
    }
    return Icons.home_repair_service_rounded;
  }

  Color _getCategoryColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) {
      return const Color(0xFFEFF7FF);
    }
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) {
      return const Color(0xFFEFFBF3);
    }
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) {
      return const Color(0xFFF0F5FF);
    }
    if (name.contains('paint') || name.contains('wall')) return const Color(0xFFFFF2E8);
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) {
      return const Color(0xFFFFF1E9);
    }
    return const Color(0xFFF1F6FF);
  }

  Color _getCategoryIconColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) {
      return const Color(0xFF7B3FE4);
    }
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) {
      return const Color(0xFF20A852);
    }
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) {
      return const Color(0xFF2F80ED);
    }
    if (name.contains('paint') || name.contains('wall')) return const Color(0xFFFF6B2C);
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) {
      return const Color(0xFFFF5722);
    }
    return const Color(0xFF3F51B5);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingProvider>().fetchBookings();
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final status = _tabs[_tabController.index].toLowerCase();
      context.read<BookingProvider>().fetchBookings(
        status: status == 'all' ? null : status,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: Column(
          children: [
            Consumer<BookingProvider>(
              builder: (_, bp, __) =>
                  ConnectionBanner(isConnected: bp.isSocketConnected),
            ),
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<BookingProvider>(
                builder: (context, bp, _) {
                  if (bp.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }

                  final bookings = bp.bookings;
                  if (bookings.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: () => bp.fetchBookings(),
                    color: AppTheme.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) =>
                          _buildBookingCard(bookings[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF075FF4), Color(0xFF0043D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            children: [
              Row(
                children: [
                  _headerIconBtn(
                    Icons.arrow_back_rounded,
                    () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'My Bookings',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Consumer<BookingProvider>(
                    builder: (_, bp, __) => Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _headerIconBtn(Icons.more_vert_rounded, () {}),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: bp.isSocketConnected
                                  ? AppTheme.success
                                  : AppTheme.error,
                              border: Border.all(color: Colors.white, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: AppTheme.primary,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: _tabs.map((t) => Tab(text: t, height: 38)).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: AppTheme.primary.withValues(alpha: 0.5),
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No bookings yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your service bookings will appear here.\nBook a service to get started!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isAccepted = booking.status == 'accepted';
    final isInstant = booking.isInstant;
    final bgColor = _getCategoryColor(booking.serviceName);
    final iconColor = _getCategoryIconColor(booking.serviceName);
    final icon = _getCategoryIcon(booking.serviceName);

    final dateStr = booking.date?.split('T')[0];
    final hasDate = dateStr != null && dateStr.isNotEmpty;

    final providerDisplay = booking.providerName == 'Provider'
        ? (isAccepted ? 'Assigning...' : '—')
        : booking.providerName;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/booking-detail',
              arguments: booking,
            ).then((_) {
              if (!mounted) return;
              context.read<BookingProvider>().fetchBookings();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    // Title + type tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  booking.serviceName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isInstant)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Instant',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hasDate ? dateStr : 'Instant Booking',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              if (!isInstant && booking.slot != null) ...[
                                const SizedBox(width: 10),
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 12,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  booking.slot!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Divider
                Container(
                  height: 1,
                  color: const Color(0xFFF0F2F5),
                ),
                const SizedBox(height: 12),
                // Bottom row: provider + status + price
                Row(
                  children: [
                    // Provider
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: AppTheme.textMuted.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 16,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        providerDisplay,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: booking.status),
                    const SizedBox(width: 10),
                    if (isAccepted) ...[
                      GestureDetector(
                        onTap: () {
                          context
                              .read<BookingProvider>()
                              .startTrackingBooking(booking);
                          Navigator.pushNamed(
                            context,
                            '/live-tracking',
                            arguments: booking.id,
                          ).then((_) {
                            if (!mounted) return;
                            context.read<BookingProvider>().fetchBookings();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.28),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'Track',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Text(
                      '₹${booking.price.toInt()}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.textMuted,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
