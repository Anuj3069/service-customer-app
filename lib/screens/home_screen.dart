import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 2) {
              Navigator.pushNamed(context, '/bookings');
              setState(() => _currentIndex = 0);
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.work_rounded),
              label: 'Services',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.schedule_rounded),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Account',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SafeArea(
      child: Column(
        children: [
          // Connection status banner (Redis socket state)
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
                  _buildHeader(),
                  if (_selectedCategory == null) ...[
                    const SizedBox(height: 20),
                    _buildSearchToggle(),
                    const SizedBox(height: 22),
                    _buildRecentPlaces(),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Select Service Category'),
                  ] else ...[
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 12),
                  _buildServicesList(),
                  const SizedBox(height: 22),
                  if (_selectedCategory == null) _buildBottomMessage(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    (auth.user?.name ?? 'U')[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello,',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    Text(
                      auth.user?.name ?? 'User',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildNotificationBell(),
            ],
          ),
        );
      },
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

  Widget _buildSearchToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/address-search'),
        child: Container(
          height: 58,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              const Icon(
                Icons.search_rounded,
                size: 24,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Consumer<AddressProvider>(
                  builder: (context, ap, _) {
                    final selected = ap.selectedAddress;
                    if (selected != null) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.displayLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            selected.shortAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      );
                    }
                    return Text(
                      'Where to...',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textMuted,
                      ),
                    );
                  },
                ),
              ),
              _togglePill('Now', _bookNow, () => setState(() => _bookNow = true)),
              _togglePill(
                'Later',
                !_bookNow,
                () => setState(() => _bookNow = false),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                          color: _getAddressColor(addr.label).withValues(alpha: 0.10),
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
                                      horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.success.withValues(alpha: 0.1),
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
      case 'home': return Icons.home_rounded;
      case 'work': return Icons.work_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  Color _getAddressColor(String label) {
    switch (label) {
      case 'home': return AppTheme.primary;
      case 'work': return AppTheme.accent;
      default: return AppTheme.success;
    }
  }



  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title == 'Select Service Category' ? 'Service Categories' : title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          if (title == 'Select Service Category')
            Text(
              'View all  >',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.35,
            ),
            itemCount: serviceProvider.services.length,
            itemBuilder: (context, index) =>
                _buildServiceTile(serviceProvider.services[index], index),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.35,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) =>
              _buildCategoryTile(categories[index], index),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.14)),
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${category.services.length} services',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textPrimary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryServices(Category category) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Material(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => setState(() => _selectedCategory = null),
                  borderRadius: BorderRadius.circular(16),
                  child: const SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(Icons.arrow_back_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${category.name} ${_getCategoryEmoji(category.name)}',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      category.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCategoryMapPreview(category),
          const SizedBox(height: 16),
          ...category.services.asMap().entries.map(
            (entry) =>
                _buildServiceListCard(entry.value, entry.key, category.name),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryMapPreview(Category category) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/nearby-workers', arguments: category);
      },
      child: Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFE9EEF8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _MapPreviewPainter())),
            Positioned(
              left: 16,
              top: 16,
              child: _mapChip(
                icon: Icons.location_on_rounded,
                label: 'Your area',
                color: AppTheme.primary,
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: _mapChip(
                icon: Icons.circle,
                label: '${category.services.length} Pros nearby',
                color: AppTheme.success,
              ),
            ),
            Center(
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Transform.rotate(
                    angle: -3.14159 / 4, // Point Northeast
                    child: const Icon(
                      Icons.navigation_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(left: 34, bottom: 28, child: _workerPin('2 mins')),
            Positioned(right: 34, bottom: 42, child: _workerPin('4 mins')),
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
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
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'View Live Map',
                      style: GoogleFonts.inter(
                        fontSize: 11,
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

  Widget _workerPin(String eta) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.success,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(
                color: AppTheme.success.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            eta,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
        ),
      ],
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
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors[index % colors.length],
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: 0,
                bottom: -2,
                child: Icon(
                  icons[index % icons.length],
                  color: AppTheme.primary.withValues(alpha: 0.75),
                  size: 42,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
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
                      fontSize: 13,
                      height: 1.2,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Shimmer.fromColors(
        baseColor: AppTheme.surface,
        highlightColor: Colors.white,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 2.35,
          ),
          itemCount: 6,
          itemBuilder: (_, __) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }

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

class _MapPreviewPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0xFFE9EEF8);
    final water = Paint()
      ..color = const Color(0xFFCFE4F6)
      ..style = PaintingStyle.fill;
    final road = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final smallRoad = Paint()
      ..color = const Color(0xFFB9C9E5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawRect(Offset.zero & size, land);
    canvas.drawOval(
      Rect.fromLTWH(
        size.width * 0.12,
        size.height * 0.18,
        size.width * 0.34,
        size.height * 0.22,
      ),
      water,
    );
    canvas.drawLine(
      Offset(-20, size.height * 0.28),
      Offset(size.width + 20, size.height * 0.74),
      road,
    );
    canvas.drawLine(
      Offset(size.width * 0.20, -20),
      Offset(size.width * 0.72, size.height + 20),
      road,
    );
    canvas.drawLine(
      Offset(-10, size.height * 0.70),
      Offset(size.width * 0.86, size.height * 0.10),
      smallRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.05, size.height * 0.48),
      Offset(size.width, size.height * 0.34),
      smallRoad,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, -10),
      Offset(size.width * 0.90, size.height + 10),
      smallRoad,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
