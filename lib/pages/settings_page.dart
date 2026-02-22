import 'package:flutter/material.dart';
import '../utils/web.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool notificationsEnabled = false;
  String subscriptionPlan = "Premium (Monthly)";

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [

          // -------- TOOL SECTION --------
          _sectionTitle("Account"),

          _settingItem(
            icon: Icons.manage_accounts,
            title: "Account settings",
            subtitle: "Go to account settings",
            onTap: () {
              openWebPage("https://app.miguel.nu/account/");
            },
          ),

          _settingItem(
            icon: Icons.star,
            title: "Subscription Plan",
            subtitle: subscriptionPlan,
            onTap: () {
              openWebPage("https://app.miguel.nu/account/plan/");
            },
          ),
          const SizedBox(height: 24),

          // -------- SWITCH --------
          _sectionTitle("Options"),

          SwitchListTile(
            title: const Text("Enable Notifications"),
            value: notificationsEnabled,
            onChanged: (value) {
              setState(() {
                notificationsEnabled = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // ---------- SECTION TITLE ----------
  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------- NORMAL ROW ----------
  Widget _settingItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}