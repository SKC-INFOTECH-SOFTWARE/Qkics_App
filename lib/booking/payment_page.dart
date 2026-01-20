import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:q_kics/booking/booking_api_service.dart';
import 'package:q_kics/booking/models/expert_slot.dart';
import 'package:q_kics/booking/models/payment_model.dart';
import 'package:q_kics/booking/services/razorpay_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class PaymentPage extends StatefulWidget {
  final ExpertSlot slot;
  final String expertName;
  final String bookingId;

  const PaymentPage({
    super.key,
    required this.slot,
    required this.expertName,
    required this.bookingId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final BookingApiService _apiService = BookingApiService();
  late RazorpayService _razorpayService;

  bool _isProcessing = false;
  PaymentResponse? _paymentResponse;
  String? _error;

  @override
  void initState() {
    super.initState();
    _razorpayService = RazorpayService(
      onSuccess: _handlePaymentSuccess,
      onFailure: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  // ================= PAYMENT HANDLERS =================

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    print("✅ Razorpay Success: ${response.paymentId}");
    setState(() => _isProcessing = true);

    try {
      final apiResponse = await _apiService.createBookingPayment(
        widget.bookingId,
      );
      if (!mounted) return;
      setState(() {
        _paymentResponse = apiResponse;
        _isProcessing = false;
      });
      HapticFeedback.heavyImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showErrorSnackBar("Backend Verification Failed: ${e.toString()}");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print("❌ Razorpay Error: ${response.code} - ${response.message}");
    setState(() => _isProcessing = false);
    _showErrorSnackBar("Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet: ${response.walletName}");
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Show success state
    if (_paymentResponse != null) {
      return _buildSuccessScreen(theme, cs);
    }

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cs.surface,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: cs.onSurface),
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
        ),
        title: Text(
          "Complete Payment",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Details Card
            _buildBookingDetailsCard(theme, cs),

            const SizedBox(height: 24),

            // Payment Summary Card
            _buildPaymentSummaryCard(theme, cs),

            const SizedBox(height: 24),

            // Error Message
            if (_error != null) _buildErrorMessage(theme, cs),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(theme, cs),
    );
  }

  // ================= BOOKING DETAILS CARD =================

  Widget _buildBookingDetailsCard(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                "Booking Details",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Expert Name
          _buildDetailRow(
            theme,
            cs,
            icon: Icons.person_outline,
            label: "Expert",
            value: widget.expertName,
          ),

          const SizedBox(height: 16),

          // Date
          _buildDetailRow(
            theme,
            cs,
            icon: Icons.event_outlined,
            label: "Date",
            value: DateFormat(
              'EEEE, MMM dd, yyyy',
            ).format(widget.slot.startDateTime),
          ),

          const SizedBox(height: 16),

          // Time
          _buildDetailRow(
            theme,
            cs,
            icon: Icons.access_time_outlined,
            label: "Time",
            value:
                "${DateFormat.jm().format(widget.slot.startDateTime)} - ${DateFormat.jm().format(widget.slot.endDateTime)}",
          ),

          const SizedBox(height: 16),

          // Duration
          _buildDetailRow(
            theme,
            cs,
            icon: Icons.timer_outlined,
            label: "Duration",
            value: "${widget.slot.durationMinutes} minutes",
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    ColorScheme cs, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= PAYMENT SUMMARY CARD =================

  Widget _buildPaymentSummaryCard(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: cs.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                "Payment Summary",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Session Fee
          _buildPriceRow(
            theme,
            cs,
            label: "Session Fee",
            amount: widget.slot.price,
          ),

          const SizedBox(height: 12),

          Divider(color: cs.onSurface.withOpacity(0.1)),

          const SizedBox(height: 12),

          // Total Amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "₹${widget.slot.price.toStringAsFixed(0)}",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    ThemeData theme,
    ColorScheme cs, {
    required String label,
    required double amount,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          "₹${amount.toStringAsFixed(0)}",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ================= ERROR MESSAGE =================

  Widget _buildErrorMessage(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================

  Widget _buildBottomBar(ThemeData theme, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isProcessing ? null : _handlePayment,
          style: ElevatedButton.styleFrom(
            backgroundColor: cs.primary,
            disabledBackgroundColor: cs.surfaceVariant,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isProcessing
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.onPrimary),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.payment_outlined, size: 20, color: Colors.white),
                    const SizedBox(width: 12),

                    Text(
                      "Complete Payment",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ================= SUCCESS SCREEN =================

  Widget _buildSuccessScreen(ThemeData theme, ColorScheme cs) {
    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 80,
                ),
              ),

              const SizedBox(height: 32),

              // Success Title
              Text(
                "Payment Successful!",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Success Message
              Text(
                "Your booking has been confirmed and a chat room has been created.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Payment Details
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.onSurface.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _buildSuccessDetailRow(
                      theme,
                      cs,
                      label: "Payment ID",
                      value: _paymentResponse!.payment.uuid
                          .substring(0, 8)
                          .toUpperCase(),
                    ),
                    const SizedBox(height: 12),
                    _buildSuccessDetailRow(
                      theme,
                      cs,
                      label: "Amount Paid",
                      value:
                          "₹${_paymentResponse!.payment.amount.toStringAsFixed(0)}",
                    ),
                    const SizedBox(height: 12),
                    _buildSuccessDetailRow(
                      theme,
                      cs,
                      label: "Status",
                      value: _paymentResponse!.payment.status,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to chat room or home
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    "Go to Home",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessDetailRow(
    ThemeData theme,
    ColorScheme cs, {
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ================= PAYMENT HANDLER =================

  void _handlePayment() {
    setState(() => _isProcessing = true);

    _razorpayService.openCheckout(
      amount: widget.slot.price,
      name: "Q-KICS",
      description: "Expert Session Booking",
      contact: "9876543210",
      email: "user@example.com",
      bookingId: widget.bookingId,
    );
  }
}
