import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();

  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _timer;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutQuart),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendOtp(
      email: _emailController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _otpSent = true;
        _otpController.clear();
      });
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully to your email.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Failed to send OTP.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  Future<void> _handleVerifyOtp() async {
    final otpCode = _otpController.text.trim();
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP.'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyOtp(
      email: _emailController.text.trim(),
      otp: otpCode,
    );

    if (!mounted) return;

    if (success) {
      final user = authProvider.user;
      if (user != null) {
        context.read<BookingProvider>().connectSocket(user.id);
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Verification failed.'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  void _showUnavailable(String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$method sign in is coming soon.'),
        backgroundColor: AppTheme.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = math.min(screenWidth - 32, 430.0);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _animController,
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B3E91).withValues(alpha: 0.10),
                        blurRadius: 34,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Header(isOtpSent: _otpSent),
                      const SizedBox(height: 8),
                      const _TeamHero(),
                      const SizedBox(height: 18),
                      Form(
                        key: _formKey,
                        child: _otpSent
                            ? _buildOtpForm(authProvider)
                            : _buildEmailForm(authProvider),
                      ),
                      if (!_otpSent) ...[
                        const SizedBox(height: 12),
                        const _DividerLabel(),
                        const SizedBox(height: 12),
                        _OutlinedLoginButton(
                          icon: const _GoogleGlyph(),
                          label: 'Continue with Google',
                          onPressed: () => _showUnavailable('Google'),
                        ),
                        const SizedBox(height: 10),
                        _OutlinedLoginButton(
                          icon: const Icon(
                            Icons.phone_iphone_rounded,
                            color: AppTheme.primary,
                            size: 22,
                          ),
                          label: 'Continue with Phone Number',
                          onPressed: () => _showUnavailable('Phone number'),
                        ),
                        const SizedBox(height: 12),
                        const _TermsText(),
                        const SizedBox(height: 18),
                        const _TrustBadges(),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm(AuthProvider authProvider) {
    return Column(
      children: [
        _AirveatTextField(
          controller: _emailController,
          hintText: 'Email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!value.contains('@')) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: GradientButton(
            text: 'Send OTP Code',
            isLoading: authProvider.isLoading,
            onPressed: _handleSendOtp,
            icon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildOtpForm(AuthProvider authProvider) {
    return Column(
      children: [
        _AirveatTextField(
          controller: _otpController,
          hintText: '000000',
          icon: Icons.lock_outline_rounded,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            LengthLimitingTextInputFormatter(6),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.outfit(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 7,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _otpSent = false;
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 16),
              label: Text(
                'Edit Email',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            const Spacer(),
            if (_resendCountdown > 0)
              Text(
                'Resend in ${_resendCountdown}s',
                style: GoogleFonts.inter(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              TextButton(
                onPressed: _handleSendOtp,
                child: Text(
                  'Resend OTP',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 52,
          child: GradientButton(
            text: 'Verify & Log In',
            isLoading: authProvider.isLoading,
            onPressed: _handleVerifyOtp,
            icon: Icons.arrow_forward_rounded,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final bool isOtpSent;

  const _Header({required this.isOtpSent});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.outfit(
              fontSize: 29,
              height: 1.08,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF111A35),
              letterSpacing: 0,
            ),
            children: [
              TextSpan(text: isOtpSent ? 'Verify ' : 'Welcome to '),
              TextSpan(
                text: isOtpSent ? 'Code' : 'Airveat',
                style: const TextStyle(color: Color(0xFF0759E6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isOtpSent
              ? 'Enter the 6-digit code sent to your email'
              : 'Sign in or register instantly',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          width: 386,
          height: 200,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF8FBFF), Color(0xFFEAF3FF)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: ClipPath(
                  clipper: _WaveClipper(flip: true),
                  child: Container(
                    width: 155,
                    height: 84,
                    color: const Color(0xFFD7E9FF),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: ClipPath(
                  clipper: _WaveClipper(),
                  child: Container(
                    width: 150,
                    height: 90,
                    color: const Color(0xFFE2F0FF),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 2,
                child: _TeamMember(
                  height: 128,
                  shirtWidth: 58,
                  hair: Color(0xFF151A28),
                  skin: Color(0xFFDFA272),
                  pose: _Pose.crossed,
                ),
              ),
              const Positioned(
                bottom: 14,
                left: 57,
                child: _TeamMember(
                  height: 146,
                  shirtWidth: 64,
                  hair: Color(0xFF171520),
                  skin: Color(0xFFCA8758),
                  pose: _Pose.relaxed,
                ),
              ),
              const Positioned(
                bottom: 8,
                left: 122,
                child: _TeamMember(
                  height: 174,
                  shirtWidth: 76,
                  hair: Color(0xFF20140F),
                  skin: Color(0xFFC98758),
                  pose: _Pose.crossed,
                ),
              ),
              const Positioned(
                bottom: 8,
                right: 118,
                child: _TeamMember(
                  height: 166,
                  shirtWidth: 70,
                  hair: Color(0xFF1D1210),
                  skin: Color(0xFFD39565),
                  pose: _Pose.folder,
                ),
              ),
              const Positioned(
                bottom: 10,
                right: 57,
                child: _TeamMember(
                  height: 168,
                  shirtWidth: 70,
                  hair: Color(0xFF7A4C2C),
                  skin: Color(0xFFD29561),
                  pose: _Pose.flag,
                  hat: true,
                ),
              ),
              const Positioned(
                bottom: 14,
                right: 2,
                child: _TeamMember(
                  height: 146,
                  shirtWidth: 64,
                  hair: Color(0xFF15151B),
                  skin: Color(0xFFC38255),
                  pose: _Pose.crossed,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Pose { crossed, relaxed, folder, flag }

class _TeamMember extends StatelessWidget {
  final double height;
  final double shirtWidth;
  final Color hair;
  final Color skin;
  final _Pose pose;
  final bool hat;

  const _TeamMember({
    required this.height,
    required this.shirtWidth,
    required this.hair,
    required this.skin,
    required this.pose,
    this.hat = false,
  });

  @override
  Widget build(BuildContext context) {
    final headSize = height * 0.24;
    final shirtHeight = height * 0.47;

    return SizedBox(
      width: shirtWidth + 12,
      height: height,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: headSize + 38,
            child: Container(
              width: shirtWidth * 0.72,
              height: height * 0.28,
              decoration: const BoxDecoration(
                color: Color(0xFF315D96),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: headSize + 17,
            child: Container(
              width: shirtWidth,
              height: shirtHeight,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF096BF4), Color(0xFF004BD2)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          Positioned(
            top: headSize + 52,
            child: Text(
              'Airveat',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: math.max(7, shirtWidth * 0.14),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
            ),
          ),
          Positioned(
            top: headSize + 26,
            left: 0,
            child: _Arm(width: shirtWidth * 0.38, skin: skin, angle: -0.38),
          ),
          Positioned(
            top: headSize + 26,
            right: 0,
            child: _Arm(width: shirtWidth * 0.38, skin: skin, angle: 0.38),
          ),
          if (pose == _Pose.folder)
            Positioned(
              top: headSize + 58,
              right: 2,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  width: shirtWidth * 0.34,
                  height: shirtWidth * 0.50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (pose == _Pose.flag)
            Positioned(
              top: headSize + 18,
              right: 0,
              child: SizedBox(
                width: 22,
                height: 58,
                child: Stack(
                  children: [
                    Positioned(
                      left: 5,
                      top: 2,
                      bottom: 0,
                      child: Container(width: 2, color: Colors.white),
                    ),
                    Positioned(
                      left: 7,
                      top: 2,
                      child: Container(
                        width: 18,
                        height: 26,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        alignment: Alignment.center,
                        child: RotatedBox(
                          quarterTurns: 1,
                          child: Text(
                            'Airveat',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: headSize * 0.58,
            child: Container(
              width: headSize * 0.42,
              height: headSize * 0.34,
              decoration: BoxDecoration(
                color: skin,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            top: hat ? 14 : 0,
            child: Container(
              width: headSize,
              height: headSize,
              decoration: BoxDecoration(
                color: skin,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: hat ? 12 : 0,
            child: Container(
              width: headSize * 1.03,
              height: headSize * 0.50,
              decoration: BoxDecoration(
                color: hair,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(headSize),
                ),
              ),
            ),
          ),
          if (hat)
            Positioned(
              top: 0,
              child: Container(
                width: headSize * 1.28,
                height: headSize * 0.30,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4E3C7),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Arm extends StatelessWidget {
  final double width;
  final Color skin;
  final double angle;

  const _Arm({
    required this.width,
    required this.skin,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: 10,
        decoration: BoxDecoration(
          color: skin,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class _AirveatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;
  final TextStyle? style;

  const _AirveatTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF143A71).withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        inputFormatters: inputFormatters,
        textAlign: textAlign,
        style: style ??
            GoogleFonts.inter(
              color: AppTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(
            color: AppTheme.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Icon(icon, color: AppTheme.textMuted, size: 22),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 15,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: const Color(0xFFCBD6E8).withValues(alpha: 0.62),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: const Color(0xFFD7DEEC).withValues(alpha: 0.95),
            thickness: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: const Color(0xFFD7DEEC).withValues(alpha: 0.95),
            thickness: 1,
          ),
        ),
      ],
    );
  }
}

class _OutlinedLoginButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  const _OutlinedLoginButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          side: BorderSide(
            color: const Color(0xFFD8E0EF).withValues(alpha: 0.95),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 28, child: Center(child: icon)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Text(
      'G',
      style: GoogleFonts.inter(
        color: const Color(0xFF4285F4),
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );
  }
}

class _TermsText extends StatelessWidget {
  const _TermsText();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.inter(
      color: AppTheme.textSecondary,
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
    );
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: base,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms of Service',
            style: base.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy.',
            style: base.copyWith(
              color: AppTheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrustBadges extends StatelessWidget {
  const _TrustBadges();

  @override
  Widget build(BuildContext context) {
    const items = [
      _BadgeData(
        icon: Icons.verified_user_outlined,
        title: 'Secure & Safe',
        subtitle: 'Your data is protected\nwith top security',
      ),
      _BadgeData(
        icon: Icons.flash_on_rounded,
        title: 'Quick & Easy',
        subtitle: 'Get started in seconds\nwith OTP login',
      ),
      _BadgeData(
        icon: Icons.account_circle_outlined,
        title: 'No Password',
        subtitle: 'Hassle-free login\nwith email OTP',
      ),
      _BadgeData(
        icon: Icons.verified_rounded,
        title: 'Trusted Care',
        subtitle: 'Verified services you\ncan rely on',
      ),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: _TrustBadge(data: items[i])),
          if (i != items.length - 1)
            Container(
              width: 1,
              height: 78,
              margin: const EdgeInsets.symmetric(horizontal: 5),
              color: const Color(0xFFE4E9F3),
            ),
        ],
      ],
    );
  }
}

class _BadgeData {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BadgeData({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _TrustBadge extends StatelessWidget {
  final _BadgeData data;

  const _TrustBadge({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(data.icon, color: AppTheme.primary, size: 23),
        ),
        const SizedBox(height: 7),
        Text(
          data.title,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: const Color(0xFF1D2741),
            fontSize: 9.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.subtitle,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 8,
            fontWeight: FontWeight.w500,
            height: 1.28,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final bool flip;

  const _WaveClipper({this.flip = false});

  @override
  Path getClip(Size size) {
    final path = Path();
    if (!flip) {
      path
        ..moveTo(size.width, 0)
        ..lineTo(size.width, size.height)
        ..quadraticBezierTo(size.width * 0.46, size.height * 0.70, 0, 0)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(0, size.height)
        ..quadraticBezierTo(size.width * 0.54, size.height * 0.70, size.width, 0)
        ..close();
    }
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) {
    return oldClipper.flip != flip;
  }
}
