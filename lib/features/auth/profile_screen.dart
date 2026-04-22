import 'package:flutter/material.dart';
import 'package:insta_counter_app/core/mock/mock_profile.dart';
import 'package:insta_counter_app/core/theme/app_theme.dart';
import 'package:insta_counter_app/providers/shell_tab_notifier.dart';
import 'package:insta_counter_app/providers/theme_variant_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = MockProfile.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppTheme.accent.withValues(alpha: 0.35),
                child: Text(
                  p.displayName.isNotEmpty ? p.displayName[0].toUpperCase() : '?',
                  style: GoogleFonts.orbitron(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.displayName,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.email,
                      style: GoogleFonts.dmSans(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Settings',
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                Consumer<ThemeVariantNotifier>(
                  builder: (context, theme, _) {
                    return ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: Text(
                        'Change Theme',
                        style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        theme.useGraphite ? 'Graphite' : 'Premium dark',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: theme.toggle,
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.router_outlined),
                  title: Text(
                    'Device Settings',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Scan & Wi-Fi provisioning',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: Colors.white54,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () =>
                      context.read<ShellTabNotifier>().setTab(1),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded),
                  title: Text(
                    'Logout',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'This is a mock profile. Nothing is persisted.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Logged out (mock)',
                            style: GoogleFonts.dmSans(),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
