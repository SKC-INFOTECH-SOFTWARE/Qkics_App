import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentMethodsSheet extends StatefulWidget {
  final double amount;
  final VoidCallback onPay;
  final bool isProcessing;

  const PaymentMethodsSheet({
    super.key,
    required this.amount,
    required this.onPay,
    this.isProcessing = false,
  });

  @override
  State<PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends State<PaymentMethodsSheet> {
  String _selectedMethod = "card"; // Default method

  // Card Form Controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (widget.isProcessing) {
      return _buildProcessingState(context);
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            "Select Payment Method",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Methods List
          _buildMethodTile(
            context,
            id: "card",
            icon: Icons.credit_card_outlined,
            title: "Credit / Debit Card",
            subtitle: "Pay seamlessly with your card",
            isSelected: _selectedMethod == "card",
          ),
          const SizedBox(height: 12),
          _buildMethodTile(
            context,
            id: "upi",
            icon: Icons.qr_code_rounded,
            title: "UPI",
            subtitle: "Google Pay, PhonePe, Paytm",
            isSelected: _selectedMethod == "upi",
          ),
          const SizedBox(height: 12),
          _buildMethodTile(
            context,
            id: "netbanking",
            icon: Icons.account_balance_outlined,
            title: "Net Banking",
            subtitle: "All Indian banks supported",
            isSelected: _selectedMethod == "netbanking",
          ),

          const SizedBox(height: 24),

          Divider(color: cs.onSurface.withOpacity(0.1)),

          const SizedBox(height: 24),

          // Card Form (Only if Card selected)
          if (_selectedMethod == "card") ...[
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Card Details",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card Number
                  _buildTextField(
                    controller: _cardNumberController,
                    label: "Card Number",
                    hint: "XXXX XXXX XXXX XXXX",
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(16),
                      _CardNumberFormatter(),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      // Expiry
                      Expanded(
                        child: _buildTextField(
                          controller: _expiryController,
                          label: "Expiry",
                          hint: "MM/YY",
                          icon: Icons.calendar_today,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(4),
                            _ExpiryDateFormatter(),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // CVV
                      Expanded(
                        child: _buildTextField(
                          controller: _cvvController,
                          label: "CVV",
                          hint: "123",
                          icon: Icons.lock_outline,
                          keyboardType: TextInputType.number,
                          isObscure: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nameController,
                    label: "Card Holder Name",
                    hint: "Name on card",
                    icon: Icons.person_outline,
                    keyboardType: TextInputType.name,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],

          if (_selectedMethod != "card")
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  "Redirecting to secure gateway...",
                  style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
                ),
              ),
            ),

          // Pay Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _handlePay,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                "Pay ₹${widget.amount.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Secure Badge
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gpp_good_outlined, size: 14, color: Colors.green),
              const SizedBox(width: 6),
              Text(
                "100% Secure Payment",
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePay() {
    if (_selectedMethod == 'card') {
      if (_formKey.currentState!.validate()) {
        // Basic validation
        if (_cardNumberController.text.length < 19) {
          // 16 digits + 3 spaces
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Invalid card number")));
          return;
        }
        widget.onPay();
      }
    } else {
      // For other methods, just proceed
      widget.onPay();
    }
  }

  Widget _buildMethodTile(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedMethod = id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? cs.primary.withOpacity(0.05) : cs.surface,
          border: Border.all(
            color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.surface
                    : cs.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? cs.primary : cs.onSurface.withOpacity(0.7),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 24)
            else
              Icon(
                Icons.circle_outlined,
                color: cs.onSurface.withOpacity(0.2),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool isObscure = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      obscureText: isObscure,
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Processing Payment",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Please wait while we secure your booking...",
            textAlign: TextAlign.center,
            style: TextStyle(color: cs.onSurface.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write(' ');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text;
    if (newValue.selection.baseOffset == 0) return newValue;

    var buffer = StringBuffer();
    for (int i = 0; i < newText.length; i++) {
      buffer.write(newText[i]);
      var nonZeroIndex = i + 1;
      if (nonZeroIndex % 2 == 0 && nonZeroIndex != newText.length) {
        buffer.write('/');
      }
    }

    var string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}
