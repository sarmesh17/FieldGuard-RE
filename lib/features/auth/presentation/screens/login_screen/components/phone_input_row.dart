import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:field_guard_re/core/constants/app_constants.dart';
import 'package:field_guard_re/core/constants/app_strings.dart';
import 'package:field_guard_re/core/theme/app_text_styles.dart';
import 'country_code_picker.dart';

class PhoneInputRow extends StatelessWidget {
  const PhoneInputRow({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CountryCodePicker(onTap: () => _showCountryPickerStub(context)),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(AppConstants.phoneNumberLength),
            ],
            style: AppTextStyles.inputText,
            decoration: InputDecoration(
              hintText: AppStrings.phoneHint,
              hintStyle: AppTextStyles.inputHint,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return AppStrings.phoneRequired;
              }
              if (value.length < AppConstants.phoneNumberLength) {
                return AppStrings.phoneInvalid;
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  void _showCountryPickerStub(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Country picker coming soon')),
    );
  }
}
