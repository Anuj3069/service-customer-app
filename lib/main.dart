import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/service_provider.dart' as sp;
import 'providers/booking_provider.dart';
import 'providers/address_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/match_result_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/booking_detail_screen.dart';
import 'screens/review_screen.dart';
import 'screens/instant_booking_screen.dart';
import 'screens/live_tracking_screen.dart';
import 'screens/nearby_workers_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/payment_result_screen.dart';
import 'screens/address_search_screen.dart';
import 'screens/saved_addresses_screen.dart';
import 'screens/add_edit_address_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AirveatCustomerApp());
}

class AirveatCustomerApp extends StatelessWidget {
  const AirveatCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => sp.ServiceProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
      ],
      child: MaterialApp(
        title: 'Airveat - Book Services',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/service-detail': (context) => const ServiceDetailScreen(),
          '/match-result': (context) => const MatchResultScreen(),
          '/bookings': (context) => const BookingsScreen(),
          '/booking-detail': (context) => const BookingDetailScreen(),
          '/review': (context) => const ReviewScreen(),
          '/instant-booking': (context) => const InstantBookingScreen(),
          '/live-tracking': (context) => const LiveTrackingScreen(),
          '/nearby-workers': (context) => const NearbyWorkersScreen(),
          '/chat': (context) => const ChatScreen(),
          '/payment': (context) => const PaymentScreen(),
          '/payment-result': (context) => const PaymentResultScreen(),
          '/address-search': (context) => const AddressSearchScreen(),
          '/saved-addresses': (context) => const SavedAddressesScreen(),
          '/add-address': (context) => const AddEditAddressScreen(),
        },
      ),
    );
  }
}
