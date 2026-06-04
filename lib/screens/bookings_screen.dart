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
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) return Icons.plumbing_rounded;
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) return Icons.cleaning_services_rounded;
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) return Icons.electrical_services_rounded;
    if (name.contains('paint') || name.contains('wall')) return Icons.format_paint_rounded;
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) return Icons.handyman_rounded;
    return Icons.home_repair_service_rounded;
  }

  Color _getCategoryColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) return const Color(0xFFEFF7FF);
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) return const Color(0xFFF0EDFF);
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) return const Color(0xFFFFF4E1);
    if (name.contains('paint') || name.contains('wall')) return const Color(0xFFFFF0F7);
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) return const Color(0xFFFFF1E9);
    return const Color(0xFFF1F6FF);
  }

  Color _getCategoryIconColor(String serviceName) {
    final name = serviceName.toLowerCase();
    if (name.contains('plumb') || name.contains('tap') || name.contains('pipe')) return const Color(0xFF2196F3);
    if (name.contains('clean') || name.contains('dust') || name.contains('wash')) return const Color(0xFF673AB7);
    if (name.contains('electr') || name.contains('wiring') || name.contains('switch')) return const Color(0xFFFF9800);
    if (name.contains('paint') || name.contains('wall')) return const Color(0xFFE91E63);
    if (name.contains('handy') || name.contains('repair') || name.contains('mount')) return const Color(0xFFFF5722);
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
      context
          .read<BookingProvider>()
          .fetchBookings(status: status == 'all' ? null : status);
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
        child: SafeArea(
          child: Column(
            children: [
              // Connection status banner (Redis socket state)
              Consumer<BookingProvider>(
                builder: (_, bp, __) => ConnectionBanner(
                  isConnected: bp.isSocketConnected,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button card
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
                      'My Bookings',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    // Three-dot menu card with connection indicator dot
                    Consumer<BookingProvider>(
                      builder: (_, bp, __) => Container(
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
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.more_vert_rounded,
                                color: AppTheme.textPrimary,
                                size: 20,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bp.isSocketConnected
                                      ? AppTheme.success
                                      : AppTheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppTheme.textMuted,
                  labelStyle: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: _tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Consumer<BookingProvider>(
                  builder: (context, bookingProvider, _) {
                    if (bookingProvider.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                        ),
                      );
                    }

                    final bookings = bookingProvider.bookings;
                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: AppTheme.textMuted, size: 64),
                            const SizedBox(height: 16),
                            Text(
                              'No bookings yet',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Book a service to get started!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => bookingProvider.fetchBookings(),
                      color: AppTheme.primary,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: bookings.length,
                        itemBuilder: (context, index) {
                          return _buildBookingCard(bookings[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
              _buildTrustBadgesRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final isAccepted = booking.status == 'accepted';
    final bgColor = _getCategoryColor(booking.serviceName);
    final iconColor = _getCategoryIconColor(booking.serviceName);
    final icon = _getCategoryIcon(booking.serviceName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
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
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Left Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                // Middle Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded,
                              size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            booking.date?.split('T')[0] ?? 'Instant',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(Icons.access_time_rounded,
                              size: 13, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            booking.slot ?? 'Now',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        booking.providerName,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    StatusBadge(status: booking.status),
                    const SizedBox(height: 8),
                    Row(
                      children: [
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
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Track',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          '₹${booking.price.toInt()}',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadgesRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(
            color: AppTheme.primary.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TrustBadgeItem(
            icon: Icons.verified_user_rounded,
            label: 'Verified Pros',
          ),
          _TrustBadgeItem(
            icon: Icons.timer_rounded,
            label: 'On-time Service',
          ),
          _TrustBadgeItem(
            icon: Icons.security_rounded,
            label: 'Secure & Safe',
          ),
        ],
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TrustBadgeItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
