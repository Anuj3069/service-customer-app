import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/address.dart';
import '../providers/address_provider.dart';

/// Add or edit a saved address.
/// Can receive a [PlacePrediction] (from search) or [Address] (for editing) as arguments.
class AddEditAddressScreen extends StatefulWidget {
  const AddEditAddressScreen({super.key});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressLine2Controller = TextEditingController();
  final _customLabelController = TextEditingController();

  String _fullAddress = '';
  String? _city;
  String? _state;
  String? _pincode;
  double _latitude = 0.0;
  double _longitude = 0.0;
  String? _placeId;
  String _selectedLabel = 'home';
  bool _isDefault = false;
  bool _isEditMode = false;
  String? _editAddressId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is PlacePrediction) {
      _fullAddress = args.displayName;
      _city = args.city;
      _state = args.state;
      _pincode = args.postcode;
      _latitude = args.latitude;
      _longitude = args.longitude;
      _placeId = args.placeId;
    } else if (args is Address) {
      _isEditMode = true;
      _editAddressId = args.id;
      _fullAddress = args.fullAddress;
      _addressLine2Controller.text = args.addressLine2 ?? '';
      _city = args.city;
      _state = args.state;
      _pincode = args.pincode;
      _latitude = args.latitude;
      _longitude = args.longitude;
      _placeId = args.placeId;
      _selectedLabel = args.label;
      _isDefault = args.isDefault;
      if (args.label == 'other' && args.customLabel != null) {
        _customLabelController.text = args.customLabel!;
      }
    }
  }

  @override
  void dispose() {
    _addressLine2Controller.dispose();
    _customLabelController.dispose();
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
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isEditMode ? 'Edit Address' : 'Save Address',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address preview card
                        _buildAddressPreview(),
                        const SizedBox(height: 24),

                        // Label selector
                        _buildLabelSection(),
                        const SizedBox(height: 24),

                        // Address line 2
                        _buildFieldLabel('Flat / Floor / Building'),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressLine2Controller,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'e.g., Flat 302, 3rd Floor, Tower B',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Custom label (only for 'other')
                        if (_selectedLabel == 'other') ...[
                          _buildFieldLabel('Custom Label'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _customLabelController,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: AppTheme.textPrimary,
                            ),
                            maxLength: 50,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Gym, Friend\'s House',
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Set as default toggle
                        _buildDefaultToggle(),
                        const SizedBox(height: 32),

                        // Save button
                        _buildSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Location',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _fullAddress.isNotEmpty ? _fullAddress : 'No location selected',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (_city != null || _pincode != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    [_city, _state, _pincode]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(', '),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Save As'),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildLabelChip('home', Icons.home_rounded, 'Home'),
            const SizedBox(width: 10),
            _buildLabelChip('work', Icons.work_rounded, 'Work'),
            const SizedBox(width: 10),
            _buildLabelChip('other', Icons.location_on_rounded, 'Other'),
          ],
        ),
      ],
    );
  }

  Widget _buildLabelChip(String value, IconData icon, String label) {
    final isSelected = _selectedLabel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLabel = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withValues(alpha: 0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppTheme.primary.withValues(alpha: 0.4)
                  : AppTheme.textMuted.withValues(alpha: 0.15),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.textMuted.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: AppTheme.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as Default',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Auto-selected for new bookings',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            activeThumbColor: AppTheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Consumer<AddressProvider>(
      builder: (context, ap, _) {
        return SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: ap.isLoading ? null : _saveAddress,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: ap.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _isEditMode ? 'Update Address' : 'Save Address',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_fullAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location first'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    final addressData = {
      'label': _selectedLabel,
      if (_selectedLabel == 'other' &&
          _customLabelController.text.trim().isNotEmpty)
        'customLabel': _customLabelController.text.trim(),
      'fullAddress': _fullAddress,
      if (_addressLine2Controller.text.trim().isNotEmpty)
        'addressLine2': _addressLine2Controller.text.trim(),
      if (_city != null && _city!.isNotEmpty) 'city': _city,
      if (_state != null && _state!.isNotEmpty) 'state': _state,
      if (_pincode != null && _pincode!.isNotEmpty) 'pincode': _pincode,
      'location': {
        'type': 'Point',
        'coordinates': [_longitude, _latitude],
      },
      if (_placeId != null) 'placeId': _placeId,
      'isDefault': _isDefault,
    };

    final ap = context.read<AddressProvider>();
    bool success;

    if (_isEditMode && _editAddressId != null) {
      success = await ap.updateAddress(_editAddressId!, addressData);
    } else {
      success = await ap.createAddress(addressData);
    }

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ap.successMessage ?? 'Address saved!'),
          backgroundColor: AppTheme.success,
        ),
      );
      ap.clearMessages();
      // Go back to wherever we came from
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ap.error ?? 'Failed to save address'),
          backgroundColor: AppTheme.error,
        ),
      );
      ap.clearMessages();
    }
  }
}
