import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:q_kics/profile/profile_route.dart';
import 'package:q_kics/providers/api_provider.dart';
import 'package:q_kics/providers/theme_provider.dart';
import 'package:q_kics/Auth/login.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final apiProvider = context.watch<ApiProvider>();
    final user = apiProvider.currentUser;

    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 600;
    final double scale = isTablet ? 1.5 : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20 * scale),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: 20 * scale,
          vertical: 16 * scale,
        ),
        children: [
          // ================= ACCOUNT SECTION =================
          _SectionHeader(title: "Account", scale: scale),
          _SettingsTile(
            icon: Icons.person_outline,
            title: "Profile Information",
            subtitle: user?.username ?? "Manage your profile",
            onTap: () {
              // Navigate to profile page
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileRoute()),
              );
            },
            scale: scale,
          ),
          _SettingsTile(
            icon: Icons.email_outlined,
            title: "Email",
            subtitle: user?.email ?? "user@example.com",
            scale: scale,
          ),
          if (user?.phone != null)
            _SettingsTile(
              icon: Icons.phone_outlined,
              title: "Phone",
              subtitle: user!.phone,
              scale: scale,
            ),

          SizedBox(height: 24 * scale),

          // ================= PREFERENCES SECTION =================
          _SectionHeader(title: "Display Preferences", scale: scale),
          Text(
            "App Theme",
            style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _ThemeCard(
                  title: "Light",
                  mode: ThemeMode.light,
                  isSelected: themeProvider.themeMode == ThemeMode.light,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.light),
                  scale: scale,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeCard(
                  title: "Dark",
                  mode: ThemeMode.dark,
                  isSelected: themeProvider.themeMode == ThemeMode.dark,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.dark),
                  scale: scale,
                  colorScheme: colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ThemeCard(
                  title: "Auto",
                  mode: ThemeMode.system,
                  isSelected: themeProvider.themeMode == ThemeMode.system,
                  onTap: () => themeProvider.setThemeMode(ThemeMode.system),
                  scale: scale,
                  colorScheme: colorScheme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Font Size Scaling
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Font Size",
                style: TextStyle(
                  fontSize: 16 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                "${(themeProvider.fontSizeFactor * 100).toInt()}%",
                style: TextStyle(
                  fontSize: 14 * scale,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: themeProvider.fontSizeFactor,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            label: "${(themeProvider.fontSizeFactor * 100).toInt()}%",
            onChanged: (double value) {
              themeProvider.setFontSizeFactor(value);
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Small", style: TextStyle(fontSize: 12 * scale)),
              Text("Large", style: TextStyle(fontSize: 12 * scale)),
            ],
          ),

          SizedBox(height: 24 * scale),

          // ================= SUPPORT SECTION =================
          _SectionHeader(title: "Support", scale: scale),
          _SettingsTile(
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {},
            scale: scale,
          ),
          _SettingsTile(
            icon: Icons.contact_support_outlined,
            title: "Contact Us",
            onTap: () {},
            scale: scale,
          ),

          SizedBox(height: 24 * scale),

          // ================= ABOUT SECTION =================
          _SectionHeader(title: "About", scale: scale),
          _SettingsTile(
            icon: Icons.info_outline,
            title: "Privacy Policy",
            onTap: () {},
            scale: scale,
          ),
          _SettingsTile(
            icon: Icons.description_outlined,
            title: "Terms of Service",
            onTap: () {},
            scale: scale,
          ),
          _SettingsTile(
            icon: Icons.code,
            title: "Version",
            subtitle: "1.0.0",
            scale: scale,
          ),

          SizedBox(height: 32 * scale),

          // ================= LOGOUT SECTION =================
          ElevatedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        "Logout",
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await apiProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error.withValues(alpha: 0.1),
              foregroundColor: colorScheme.error,
              elevation: 0,
              minimumSize: Size(double.infinity, 56 * scale),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * scale),
              ),
            ),
            child: Text(
              "Logout",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * scale,
              ),
            ),
          ),

          SizedBox(height: 48 * scale),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final double scale;

  const _SectionHeader({required this.title, required this.scale});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12 * scale),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12 * scale,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final double scale;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: EdgeInsets.all(8 * scale),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12 * scale),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 22 * scale,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 16 * scale, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 13 * scale))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, size: 20 * scale)
          : null,
      onTap: onTap,
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final ThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final double scale;
  final ColorScheme colorScheme;

  const _ThemeCard({
    required this.title,
    required this.mode,
    required this.isSelected,
    required this.onTap,
    required this.scale,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 250 * scale,
            decoration: BoxDecoration(
              color: mode == ThemeMode.light
                  ? Colors.white
                  : mode == ThemeMode.dark
                  ? const Color(0xFF1E1E1E)
                  : null,
              gradient: mode == ThemeMode.system
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, const Color(0xFF1E1E1E)],
                    )
                  : null,
              borderRadius: BorderRadius.circular(12 * scale),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11 * scale),
              child: _buildSkeleton(mode),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<bool>(
                value: true,
                groupValue: isSelected,
                onChanged: (_) => onTap(),
                activeColor: colorScheme.primary,
                visualDensity: VisualDensity.compact,
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14 * scale,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton(ThemeMode mode) {
    bool isDark = mode == ThemeMode.dark;
    bool isSystem = mode == ThemeMode.system;

    Color bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    Color contentColor = isDark ? Colors.white24 : Colors.grey[200]!;
    Color appBarColor = colorScheme.primary;

    if (isSystem) {
      return Stack(
        children: [
          _skeletonLayout(Colors.white, Colors.grey[200]!, appBarColor, false),
          ClipPath(
            clipper: _DiagonalClipper(),
            child: _skeletonLayout(
              const Color(0xFF1E1E1E),
              Colors.white24,
              appBarColor,
              true,
            ),
          ),
        ],
      );
    }

    return _skeletonLayout(bgColor, contentColor, appBarColor, isDark);
  }

  Widget _skeletonLayout(Color bg, Color content, Color color, bool isDark) {
    return Container(
      color: bg,
      child: Column(
        children: [
          // Status Bar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 20,
                  height: 4,
                  decoration: BoxDecoration(
                    color: content,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: content,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: content,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // AppBar
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: color,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  height: 6,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          ),
          // Body Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: content,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 0,
                            height: 6,
                            decoration: BoxDecoration(
                              color: content,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 25,
                            height: 4,
                            decoration: BoxDecoration(
                              color: content.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: content.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 12),
                  // Detailed body mockup
                  Container(
                    width: double.infinity,
                    height: 65,
                    decoration: BoxDecoration(
                      color: content,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 6,
                        decoration: BoxDecoration(
                          color: content,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 6,
                        decoration: BoxDecoration(
                          color: content,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 70,
                    height: 4,
                    decoration: BoxDecoration(
                      color: content.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom Nav
          Container(
            height: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: content, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                4,
                (i) => Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: (i == 0) ? color : content,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
