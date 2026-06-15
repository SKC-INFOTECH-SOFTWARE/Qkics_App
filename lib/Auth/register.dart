import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/Auth/login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _errorMessage;
  String? _successMessage;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _animationController.forward();
  }

  Color _registerButtonColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark
        ? const Color(0xFF8B0000)
        : Theme.of(context).colorScheme.primary;
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return InputDecoration(
      prefixIcon: Icon(icon),
      hintText: hint,
      filled: true,
      fillColor: scheme.surface,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error),
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final api = context.read<ApiProvider>();
    final result = await api.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      password2: _confirmPasswordController.text,
      userType: "normal",
    );

    if (!mounted) return;

    if (result["success"] == true) {
      setState(() {
        _successMessage =
            result["message"] ?? "Account created successfully!";
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      });
    } else {
      setState(() => _errorMessage = result["message"]);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final maxWidth = isTablet ? 600.0 : double.infinity;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32 : 24,
                    vertical: isTablet ? 30 : 28,
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          children: [
                            Container(
                              width: isTablet ? 220 : 130,
                              height: isTablet ? 220 : 130,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: isDark
                                    ? []
                                    : [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.12),
                                          blurRadius: 24,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/icon.jpg',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              "Join Q-KICS",
                              style: GoogleFonts.aDLaMDisplay(
                                fontSize: isTablet ? 40 : 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Quantum Knowledge & Innovation Control System",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),

                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: isDark
                              ? []
                              : [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.08),
                                    blurRadius: 28,
                                    offset: const Offset(0, 16),
                                  ),
                                ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _usernameController,
                                decoration: _fieldDecoration(
                                  context,
                                  hint: "Username",
                                  icon: Icons.person_outline,
                                ),
                                validator: (v) =>
                                    v!.isEmpty ? "Enter username" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                decoration: _fieldDecoration(
                                  context,
                                  hint: "Email",
                                  icon: Icons.email_outlined,
                                ),
                                validator: (v) =>
                                    !v!.contains("@") ? "Enter valid email" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _phoneController,
                                decoration: _fieldDecoration(
                                  context,
                                  hint: "Phone",
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (v) =>
                                    v!.length < 10 ? "Enter valid phone" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: _fieldDecoration(
                                  context,
                                  hint: "Password",
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) =>
                                    v!.length < 6 ? "Password too short" : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                decoration: _fieldDecoration(
                                  context,
                                  hint: "Confirm Password",
                                  icon: Icons.lock_outline,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirm = !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) =>
                                    v != _passwordController.text
                                        ? "Passwords do not match"
                                        : null,
                              ),

                              if (_successMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _successMessage!,
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _registerButtonColor(context),
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? LoadingAnimationWidget
                                          .threeArchedCircle(
                                          color: Colors.white,
                                          size: 26,
                                        )
                                      : const Text(
                                          "Create Account",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account? "),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const LoginPage(),
                                        ),
                                      );
                                    },
                                    child: const Text("Log in"),
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
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
