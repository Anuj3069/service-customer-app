import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';
import '../models/service.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/service_provider.dart' as sp;
import '../providers/address_provider.dart';
import '../widgets/connection_banner.dart';
import '../widgets/notification_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _bookNow = true;
  Category? _selectedCategory;

  // ignore: unused_element
  String _getCategoryEmoji(String name) {
    final cleanName = name.toLowerCase();
    if (cleanName.contains('plumbing')) return '🚰';
    if (cleanName.contains('cleaning')) return '🧹';
    if (cleanName.contains('electric')) return '⚡';
    if (cleanName.contains('paint')) return '🎨';
    if (cleanName.contains('appliance')) return '🔌';
    if (cleanName.contains('handyman')) return '🔨';
    return '🛠️';
  }

  IconData _getCategoryIcon(String name) {
    final cleanName = name.toLowerCase();
    if (cleanName.contains('plumbing')) {
      return Icons.plumbing_rounded;
    }
    if (cleanName.contains('cleaning')) {
      return Icons.cleaning_services_rounded;
    }
    if (cleanName.contains('electric')) {
      return Icons.electrical_services_rounded;
    }
    if (cleanName.contains('paint')) {
      return Icons.format_paint_rounded;
    }
    if (cleanName.contains('handyman')) {
      return Icons.handyman_rounded;
    }
    return Icons.home_repair_service_rounded;
  }

  Color _getCategoryColor(String name) {
    final cleanName = name.toLowerCase();
    if (cleanName.contains('plumbing')) {
      return const Color(0xFFEFF7FF);
    }
    if (cleanName.contains('cleaning')) {
      return const Color(0xFFEFFBF3);
    }
    if (cleanName.contains('electric')) {
      return const Color(0xFFF0F5FF);
    }
    if (cleanName.contains('paint')) {
      return const Color(0xFFFFF2E8);
    }
    if (cleanName.contains('handyman')) {
      return const Color(0xFFFFF1E9);
    }
    return const Color(0xFFF1F6FF);
  }

  Color _getCategoryIconColor(String name) {
    final cleanName = name.toLowerCase();
    if (cleanName.contains('plumbing')) return const Color(0xFF7B3FE4);
    if (cleanName.contains('cleaning')) return const Color(0xFF20A852);
    if (cleanName.contains('electric')) return const Color(0xFF2F80ED);
    if (cleanName.contains('paint')) return const Color(0xFFFF6B2C);
    if (cleanName.contains('handyman')) return const Color(0xFFFF5722);
    return const Color(0xFF3F51B5);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<sp.ServiceProvider>().fetchServices();
      context.read<AddressProvider>().fetchAddresses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildServicesTab(),
            _buildBookingsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Consumer<BookingProvider>(
            builder: (context, bp, _) {
              final data = bp.acceptedBookingNotification;
              if (data == null) return const SizedBox.shrink();
              return _buildAcceptedBanner(context, bp, data);
            },
          ),
          _buildReferenceBottomNav(),
        ],
      ),
    );
  }

  Widget _buildAcceptedBanner(
    BuildContext context,
    BookingProvider bp,
    Map<String, dynamic> data,
  ) {
    final providerRaw = data['provider'];
    final providerName = (data['providerName']?.toString()) ??
        (providerRaw is Map ? providerRaw['name']?.toString() : null) ??
        'Your provider';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.success, Color(0xFF0E9E56)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.success.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Booking Accepted!',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '$providerName is on your booking',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              bp.clearAcceptedBooking();
              Navigator.pushNamed(context, '/bookings');
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'View',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: bp.clearAcceptedBooking,
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Consumer<BookingProvider>(
          builder: (_, bp, __) =>
              ConnectionBanner(isConnected: bp.isSocketConnected),
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedCategory == null) ...[
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildSectionTitle('Select Service Category'),
                  const SizedBox(height: 10),
                  _buildServicesList(),
                  const SizedBox(height: 12),
                  _buildAllServicesCard(),
                  const SizedBox(height: 12),
                  _buildMonthBookingCard(),
                  const SizedBox(height: 12),
                  _buildBookingSection(),
                  const SizedBox(height: 12),
                  _buildPromoBanner(),
                ] else ...[
                  SizedBox(height: MediaQuery.of(context).padding.top + 18),
                  _buildCategoryServices(_selectedCategory!),
                ],
                const SizedBox(height: 92),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF075FF4), Color(0xFF0043D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildHeaderLocation()),
              _buildNotificationBell(),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchToggle(),
        ],
      ),
    );
  }

  Widget _buildNotificationBell() {
    return Consumer<BookingProvider>(
      builder: (context, bp, _) {
        final unread = bp.unreadNotificationCount;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _roundIcon(Icons.notifications_none_rounded, () {
              NotificationPanel.show(
                context,
                notifications: bp.realtimeNotifications,
                unreadCount: unread,
                onClear: () => bp.clearNotifications(),
                onMarkRead: (index) => bp.markNotificationRead(index),
              );
            }),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.error,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderLocation() {
    return Consumer<AddressProvider>(
      builder: (context, ap, _) {
        final selected = ap.selectedAddress;
        final label = selected == null
            ? 'Howrah, West Bengal'
            : '${selected.displayLabel}, ${selected.shortAddress}';

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/address-search'),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 18,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchToggle() {
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = 1),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 23,
              color: AppTheme.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Search for a service',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 22),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _togglePill(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        width: 74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildRecentPlaces() {
    return Consumer<AddressProvider>(
      builder: (context, ap, _) {
        final addrs = ap.addresses;

        if (addrs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/address-search'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.76),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Your First Address',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Save addresses for faster bookings',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Show up to 3 saved addresses
        final displayAddrs = addrs.take(3).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: displayAddrs.map((addr) {
              return GestureDetector(
                onTap: () {
                  ap.selectAddress(addr);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 ${addr.displayLabel} selected'),
                      backgroundColor: AppTheme.success,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ap.selectedAddress?.id == addr.id
                        ? AppTheme.primary.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.76),
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.textMuted.withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _getAddressColor(
                            addr.label,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getAddressIcon(addr.label),
                          color: _getAddressColor(addr.label),
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  addr.displayLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                if (addr.isDefault) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Default',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              addr.shortAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (ap.selectedAddress?.id == addr.id)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primary,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label) {
      case 'home':
        return Icons.home_rounded;
      case 'work':
        return Icons.work_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Color _getAddressColor(String label) {
    switch (label) {
      case 'home':
        return AppTheme.primary;
      case 'work':
        return AppTheme.accent;
      default:
        return AppTheme.success;
    }
  }

  double _categoryStartingPrice(Category category) {
    if (category.services.isEmpty) return 299;
    return category.services
        .map((service) => service.basePrice)
        .where((price) => price > 0)
        .fold<double>(
          category.services.first.basePrice > 0
              ? category.services.first.basePrice
              : 299,
          (lowest, price) => price < lowest ? price : lowest,
        );
  }

  Widget _buildAllServicesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => setState(() => _currentIndex = 1),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.24),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Services',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Browse everything in one place',
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthBookingCard() {
    return Consumer<sp.ServiceProvider>(
      builder: (context, serviceProvider, _) {
        final monthServices = serviceProvider.serviceCategories
            .expand((cat) => cat.services)
            .where((s) => s.allowMonthBooking)
            .toList();

        if (monthServices.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(
              context,
              '/month-services',
              arguments: monthServices,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E1B4B), Color(0xFF3730A3)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3730A3).withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 24,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${monthServices.length} service${monthServices.length > 1 ? 's' : ''} available · Half or Full day',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECF4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFFF8A00),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _bookNow ? 'Book\nNow' : 'Book\nLater',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      height: 0.95,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _bookNow
                        ? 'Get help from nearby pros'
                        : 'Pick a schedule that fits your routine',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      height: 1.15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                _bookingModeChip('Book Now', _bookNow, () {
                  setState(() => _bookNow = true);
                }),
                const SizedBox(height: 7),
                _bookingModeChip('Book Later', !_bookNow, () {
                  setState(() => _bookNow = false);
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingModeChip(String label, bool selected, VoidCallback onTap) {
    return SizedBox(
      width: 104,
      height: 31,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFFFF7A00) : Colors.white,
          foregroundColor: selected ? Colors.white : AppTheme.primary,
          padding: EdgeInsets.zero,
          elevation: 0,
          side: BorderSide(
            color: selected
                ? const Color(0xFFFF7A00)
                : AppTheme.primary.withValues(alpha: 0.22),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 92,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: const Color(0xFF061D4A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned(
              right: 7,
              top: 2,
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFA400), width: 2),
                ),
                child: Center(
                  child: Text(
                    '15\nMIN',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      height: 0.9,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFA400),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF7A00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'NEW',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 17,
              child: Text(
                'Help arrives in\n15 min',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  height: 0.93,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 53,
              child: Text(
                'Trusted professionals.\nOn-time, every time.',
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  height: 1.12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.86),
                ),
              ),
            ),
            Positioned(
              right: 92,
              top: 16,
              child: Icon(
                Icons.engineering_rounded,
                color: const Color(0xFF0D6BFF),
                size: 50,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Row(
                children: [
                  _promoStat(
                    Icons.flash_on_rounded,
                    'Quick Response\nWithin 15 min',
                  ),
                  _promoStat(
                    Icons.verified_user_rounded,
                    'Verified & Trusted\n100% safe',
                  ),
                  _promoStat(Icons.eco_rounded, 'Top Rated\nProfessionals'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _promoStat(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 21,
            height: 21,
            decoration: const BoxDecoration(
              color: Color(0xFF14376F),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFFFFB21A), size: 13),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 7,
                height: 1.05,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (title == 'Select Service Category') ...[
            const Icon(
              Icons.grid_view_rounded,
              color: AppTheme.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title == 'Select Service Category' ? 'Service Category' : title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (title == 'Select Service Category')
            GestureDetector(
              onTap: () => setState(() => _currentIndex = 1),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Consumer<sp.ServiceProvider>(
      builder: (context, serviceProvider, _) {
        if (serviceProvider.isLoading) return _buildShimmerGrid();
        if (serviceProvider.error != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.error,
                    size: 42,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load services',
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                  TextButton(
                    onPressed: () => serviceProvider.fetchServices(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final categories = serviceProvider.serviceCategories;
        if (categories.isEmpty && serviceProvider.services.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No services available',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        if (_selectedCategory != null) {
          return _buildCategoryServices(_selectedCategory!);
        }

        if (categories.isEmpty) {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 92,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.74,
            ),
            itemCount: serviceProvider.services.take(8).length,
            itemBuilder: (context, index) =>
                _buildServiceTile(serviceProvider.services[index], index),
          );
        }

        final displayCategories = categories.take(8).toList();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 92,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.74,
          ),
          itemCount: displayCategories.length,
          itemBuilder: (context, index) =>
              _buildCategoryTile(displayCategories[index], index),
        );
      },
    );
  }

  Widget _buildCategoryTile(Category category, int index) {
    final color = _getCategoryColor(category.name);
    final icon = _getCategoryIcon(category.name);
    final iconColor = _getCategoryIconColor(category.name);

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 9, 6, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE8ECF4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 10.5,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '\u20B9 ${_categoryStartingPrice(category).toInt()}',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryServices(Category category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gradient header
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF075FF4), Color(0xFF0043D1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 12,
            16,
            22,
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedCategory = null),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.name} ${_getCategoryEmoji(category.name)}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      category.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.80),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCategoryMapPreview(category),
              const SizedBox(height: 16),
              ...category.services.asMap().entries.map(
                (entry) => _buildServiceListCard(
                  entry.value,
                  entry.key,
                  category.name,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMapPreview(Category category) {
    return Consumer<AddressProvider>(
      builder: (context, ap, _) {
        final coords = ap.selectedAddress?.coordinates;
        // GeoJSON: [lng, lat]
        final center = (coords != null && coords.length >= 2)
            ? LatLng(coords[1], coords[0])
            : const LatLng(22.5726, 88.3639); // fallback: Kolkata

        return GestureDetector(
          onTap: () =>
              Navigator.pushNamed(context, '/nearby-workers', arguments: category),
          child: Container(
            height: 200,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Live map (non-interactive)
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.customer_app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: center,
                            width: 46,
                            height: 46,
                            child: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary.withValues(alpha: 0.30),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Transform.rotate(
                                  angle: -3.14159 / 4,
                                  child: const Icon(
                                    Icons.navigation_rounded,
                                    color: AppTheme.primary,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Top chips
                Positioned(
                  left: 12,
                  top: 12,
                  child: _mapChip(
                    icon: Icons.location_on_rounded,
                    label: 'Your area',
                    color: AppTheme.primary,
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: _mapChip(
                    icon: Icons.circle,
                    label: '${category.services.length} Pros nearby',
                    color: AppTheme.success,
                  ),
                ),
                // View Live Map button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.map_rounded,
                          color: Colors.white,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View Live Map',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mapChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceListCard(
    Service service,
    int index,
    String categoryName,
  ) {
    final color = _getCategoryColor(categoryName);
    final icon = _getCategoryIcon(categoryName);
    final iconColor = _getCategoryIconColor(categoryName);
    final discountPrice = (service.basePrice * 1.25).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              '/service-detail',
              arguments: service,
            ),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: iconColor, size: 30),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${service.duration} min · ${service.description}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule_rounded,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _bookNow ? 'Arrives in 6 min' : 'Choose slot',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${service.basePrice.toInt()}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                      ),
                      Text(
                        '₹$discountPrice',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '4.8',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceTile(Service service, int index) {
    final icons = [
      Icons.local_shipping_rounded,
      Icons.yard_rounded,
      Icons.edit_note_rounded,
      Icons.elderly_rounded,
      Icons.business_center_rounded,
      Icons.pets_rounded,
    ];
    final colors = [
      const Color(0xFFFFF1E9),
      const Color(0xFFEFF7FF),
      const Color(0xFFFFF4E1),
      const Color(0xFFF1F6FF),
      const Color(0xFFF0EDFF),
      const Color(0xFFFFF0F7),
    ];
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 70)),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
      child: GestureDetector(
        onTap: () =>
            Navigator.pushNamed(context, '/service-detail', arguments: service),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 9, 6, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE8ECF4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icons[index % icons.length],
                  color: AppTheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Text(
                  service.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '\u20B9 ${service.basePrice.toInt()}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surface,
        highlightColor: Colors.white,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 92,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 0.74,
          ),
          itemCount: 8,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildBottomMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.70),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.10)),
        ),
        child: Text(
          'On your services everytime\nBook Now or Book Later',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            height: 1.35,
            fontWeight: FontWeight.w800,
            color: AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingsTab() => const Center(child: Text('Bookings'));

  Widget _buildServicesTab() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            _buildSectionTitle('Services'),
            const SizedBox(height: 14),
            _buildServicesList(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return Column(
              children: [
                const SizedBox(height: 26),
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      (auth.user?.name ?? 'U')[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  auth.user?.name ?? 'User',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  auth.user?.email ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 28),
                _buildProfileOption(
                  Icons.receipt_long_rounded,
                  'My Bookings',
                  () => Navigator.pushNamed(context, '/bookings'),
                  iconBgColor: const Color(0xFFEFF7FF),
                  iconColor: AppTheme.primary,
                ),
                _buildProfileOption(
                  Icons.location_on_rounded,
                  'Saved Addresses',
                  () => Navigator.pushNamed(context, '/saved-addresses'),
                  iconBgColor: const Color(0xFFF1EEFF),
                  iconColor: AppTheme.accent,
                ),
                _buildProfileOption(
                  Icons.star_rounded,
                  'My Reviews',
                  () {},
                  iconBgColor: const Color(0xFFFFF0F7),
                  iconColor: const Color(0xFFD81B60),
                ),
                _buildProfileOption(
                  Icons.settings_rounded,
                  'Settings',
                  () {},
                  iconBgColor: const Color(0xFFE8F5E9),
                  iconColor: AppTheme.success,
                ),
                _buildProfileOption(
                  Icons.help_outline_rounded,
                  'Help & Support',
                  () {},
                  iconBgColor: const Color(0xFFFFF3E0),
                  iconColor: const Color(0xFFEF6C00),
                ),
                const SizedBox(height: 14),
                _buildProfileOption(
                  Icons.logout_rounded,
                  'Logout',
                  () async {
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  isDestructive: true,
                  iconBgColor: const Color(0xFFFFEBEE),
                  iconColor: AppTheme.error,
                ),
                _buildSafetyBanner(),
                const SizedBox(height: 100),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSafetyBanner() {
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: AppTheme.primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your safety is our priority',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Verified professionals, background checks, & 24/7 assistance.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? AppTheme.error
                          : AppTheme.textPrimary,
                    ),
                  ),
                ),
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

  Widget _buildReferenceBottomNav() {
    return Container(
      height: 64 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(
        left: 10,
        right: 10,
        top: 5,
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.textMuted.withValues(alpha: 0.18)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _referenceNavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: _currentIndex == 0,
            onTap: () => setState(() => _currentIndex = 0),
          ),
          _referenceNavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Bookings',
            selected: false,
            onTap: () => Navigator.pushNamed(context, '/bookings'),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ),
          ),
          _referenceNavItem(
            icon: Icons.monitor_heart_outlined,
            label: 'Activity',
            selected: false,
            onTap: () => Navigator.pushNamed(context, '/bookings'),
          ),
          _referenceNavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: _currentIndex == 3,
            onTap: () => setState(() => _currentIndex = 3),
          ),
        ],
      ),
    );
  }

  Widget _referenceNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppTheme.primary : AppTheme.textMuted;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 54,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIcon(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: AppTheme.textPrimary),
        ),
      ),
    );
  }
}

