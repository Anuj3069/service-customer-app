import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpayment/cfwebcheckoutpayment.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfpaymentgateway/cfpaymentgatewayservice.dart';
import 'package:flutter_cashfree_pg_sdk/api/cfsession/cfsession.dart';
import 'package:flutter_cashfree_pg_sdk/utils/cfenums.dart';
import 'package:flutter_cashfree_pg_sdk/api/cferrorresponse/cferrorresponse.dart';

import '../config/theme.dart';
import '../models/booking.dart';
import '../services/payment_api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentApiService _paymentApiService = PaymentApiService();
  final CFPaymentGatewayService _cfPaymentGatewayService = CFPaymentGatewayService();

  Booking? _booking;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Configure Cashfree SDK callbacks
    _cfPaymentGatewayService.setCallback(_verifyPaymentCallback, _onErrorCallback);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _booking ??= ModalRoute.of(context)!.settings.arguments as Booking;
  }

  /// Cashfree success callback
  void _verifyPaymentCallback(String orderId) async {
    if (_booking == null) return;
    
    debugPrint('[PaymentScreen] SDK Callback success. Order ID: $orderId');
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // Call backend to verify payment status
      final result = await _paymentApiService.verifyPayment(_booking!.id);
      final String status = result['status']?.toString().toLowerCase() ?? '';

      if (mounted) {
        if (status == 'paid') {
          Navigator.pushReplacementNamed(
            context,
            '/payment-result',
            arguments: {
              'booking': _booking,
              'success': true,
              'message': 'Payment completed successfully!',
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/payment-result',
            arguments: {
              'booking': _booking,
              'success': false,
              'message': 'Payment verification status: ${status.toUpperCase()}',
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Verification error: ${e.toString()}';
        });
      }
    }
  }

  /// Cashfree error callback
  void _onErrorCallback(CFErrorResponse errorResponse, String orderId) {
    debugPrint('[PaymentScreen] SDK Callback error. Order ID: $orderId | Code: ${errorResponse.getCode()} | Message: ${errorResponse.getMessage()}');
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Payment failed: ${errorResponse.getMessage()}';
      });
    }
  }

  /// Initiate the payment flow by calling the backend to create an order
  Future<void> _startPaymentFlow() async {
    if (_booking == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Call Backend to create payment order and fetch session
      final paymentDetails = await _paymentApiService.initiatePayment(_booking!.id);
      final String? paymentSessionId = paymentDetails['paymentSessionId'];
      final String? orderId = paymentDetails['orderId'];

      if (paymentSessionId == null || orderId == null) {
        throw Exception('Server failed to return paymentSessionId or orderId');
      }

      // 2. Launch Cashfree SDK Web Checkout
      final session = CFSessionBuilder()
          .setEnvironment(CFEnvironment.SANDBOX) // Set to PRODUCTION for live payments
          .setOrderId(orderId)
          .setPaymentSessionId(paymentSessionId)
          .build();

      final cfWebCheckoutPayment = CFWebCheckoutPaymentBuilder()
          .setSession(session)
          .build();

      await _cfPaymentGatewayService.doPayment(cfWebCheckoutPayment);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  Future<void> _markPaidByCash() async {
    if (_booking == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      await _paymentApiService.markCashPayment(_booking!.id);
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/payment-result',
          arguments: {
            'booking': _booking,
            'success': true,
            'message': 'Cash payment recorded successfully!',
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.toString().replaceAll('ApiException: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = _booking;
    if (booking == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
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
                        onPressed: _isProcessing ? null : () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppTheme.textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Checkout',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Booking Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  booking.serviceName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'COMPLETED',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Provider: ${booking.providerName}',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Divider(height: 32, color: Colors.black12),
                            _detailRow('Date', booking.date?.split('T')[0] ?? ''),
                            _detailRow('Slot', booking.slot ?? 'Instant'),
                            _detailRow('Booking Reference', '#${booking.id.substring(booking.id.length - 8).toUpperCase()}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price Card
                      GlassCard(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Payment Summary',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _detailRow('Service Fee', '₹${booking.price.toInt()}'),
                            _detailRow('GST (18%)', 'Included'),
                            const Divider(height: 24, color: Colors.black12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Payable',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '₹${booking.price.toInt()}',
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: AppTheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.error.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              color: AppTheme.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      if (_isProcessing)
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(color: AppTheme.primary),
                              SizedBox(height: 16),
                              Text('Connecting to Payment Gateway...'),
                            ],
                          ),
                        )
                      else
                        Column(
                          children: [
                            GradientButton(
                              text: 'Pay Online (₹${booking.price.toInt()})',
                              icon: Icons.payment_rounded,
                              onPressed: _startPaymentFlow,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: OutlinedButton.icon(
                                onPressed: _markPaidByCash,
                                icon: const Icon(Icons.payments_rounded),
                                label: Text(
                                  'Paid by Cash',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.success,
                                  side: const BorderSide(color: AppTheme.success),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
