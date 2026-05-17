import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_guard_re/features/shops/data/models/create_shop_request.dart';
import 'package:field_guard_re/features/shops/presentation/providers/shop_provider.dart';

class CreateGeofenceForm extends ConsumerStatefulWidget {
  final double latitude;
  final double longitude;

  const CreateGeofenceForm({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  ConsumerState<CreateGeofenceForm> createState() => _CreateGeofenceFormState();
}

class _CreateGeofenceFormState extends ConsumerState<CreateGeofenceForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final request = CreateShopRequest(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      latitude: widget.latitude,
      longitude: widget.longitude,
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );

    final success =
        await ref.read(shopNotifierProvider.notifier).createShop(request);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopNotifierProvider);
    final isLoading = state is ShopLoading;
    final error = state is ShopError ? state.message : null;

    return Padding(
      // Pushes the form up when keyboard appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                const Text(
                  'Create Geofence',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Fill in the shop details for this location.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 20),

                // Auto-filled location info row
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD1FADF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Color(0xFF157347),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Lat: ${widget.latitude.toStringAsFixed(6)}   '
                          'Lng: ${widget.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF157347),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Shop Name
                _FormField(
                  controller: _nameController,
                  label: 'Shop Name',
                  hint: 'e.g. Rajan Enterprises',
                  icon: Icons.store_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Shop name is required' : null,
                ),
                const SizedBox(height: 16),

                // Address
                _FormField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'e.g. Birgunj, Nepal',
                  icon: Icons.location_on_outlined,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Address is required' : null,
                ),
                const SizedBox(height: 16),

                // Contact Name
                _FormField(
                  controller: _contactNameController,
                  label: 'Contact Name',
                  hint: 'e.g. Bhupendra Prasad',
                  icon: Icons.person_outline,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Contact name is required' : null,
                ),
                const SizedBox(height: 16),

                // Contact Phone
                _FormField(
                  controller: _contactPhoneController,
                  label: 'Contact Phone',
                  hint: 'e.g. 98042084753',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Contact phone is required';
                    }
                    if (v.trim().length < 7) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // API error message
                if (error != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF157347),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Create Geofence',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?) validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.validator,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF157347), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
