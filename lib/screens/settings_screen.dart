import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation_data.dart';
import 'about_screen.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NavigationProvider>(context);
    final isDark = provider.isDarkTheme;

    return Scaffold(
      appBar: AppBar(title: const Text("SETTINGS")),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          children: [
            // Preference category: Application Theme
            _buildSectionHeader("App Interface Configuration"),

            SwitchListTile(
              secondary: const Icon(Icons.dark_mode, color: Color(0xFF5C2219)),
              title: const Text(
                "Dark Theme Mode",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text("Switch app colors for night viewing"),
              value: isDark,
              onChanged: (val) {
                provider.setDarkTheme(val);
              },
            ),

            SwitchListTile(
              secondary: const Icon(
                Icons.notifications_active,
                color: Color(0xFF5C2219),
              ),
              title: const Text(
                "Emergency Notifications",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Push urgent alert warnings when backgrounded",
              ),
              value: provider.notificationsEnabled,
              onChanged: (val) {
                provider.setNotificationsEnabled(val);
              },
            ),

            const Divider(),

            // Preference category: Assistive Voice
            _buildSectionHeader("Aira Stick Speech Output"),

            ListTile(
              leading: const Icon(Icons.g_translate, color: Color(0xFF5C2219)),
              title: const Text(
                "Voice Output Language",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(provider.voiceLanguage),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showLanguageSelector(context, provider),
            ),

            // Voice Volume Slider inside custom list card structure
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 20,
                            color: Color(0xFF5C2219),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Voice Readout Volume",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "${(provider.voiceVolume * 100).toInt()}%",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE58554),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: provider.voiceVolume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: const Color(0xFF5C2219),
                    inactiveColor: Colors.blueGrey.shade100,
                    onChanged: (val) {
                      provider.setVoiceVolume(val);
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Preference category: Safety Contacts
            _buildSectionHeader("Caretaker / Guardian Contacts"),

            ListTile(
              leading: const Icon(
                Icons.contact_phone,
                color: Color(0xFF5C2219),
              ),
              title: const Text(
                "Emergency Phone Routing",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(provider.emergencyContact),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: () => _showEmergencyContactDialog(context, provider),
            ),

            const Divider(),

            // Preference category: Device Settings
            _buildSectionHeader("Hardware Link Control"),

            ListTile(
              leading: const Icon(
                Icons.bluetooth_audio,
                color: Color(0xFF5C2219),
              ),
              title: const Text(
                "Bluetooth Link configurations",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                provider.hardwareInfo.isEsp32Connected
                    ? "Connected: MAC ${provider.hardwareInfo.bluetoothAddress}"
                    : "Device Link - Offline",
              ),
              trailing: Switch(
                value: provider.hardwareInfo.isEsp32Connected,
                onChanged: (val) {
                  provider.toggleBluetoothConnection();
                },
              ),
            ),

            ListTile(
              leading: const Icon(Icons.restart_alt, color: Color(0xFFD90429)),
              title: const Text(
                "Factory Reset Stick Hardware",
                style: TextStyle(
                  color: Color(0xFFD90429),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                "Flashes and clears memory configs on ESP32",
              ),
              onTap: () => _showResetConfirmation(context),
            ),

            const Divider(),

            // Preference category: About
            _buildSectionHeader("Developer & System Details"),



            ListTile(
              leading: const Icon(Icons.menu_book, color: Color(0xFF5C2219)),
              title: const Text(
                "User Guide & System Features",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "How to set up the Aira stick and key system features",
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        const OnboardingScreen(readOnly: true),
                  ),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.info_outline, color: Color(0xFF5C2219)),
              title: const Text(
                "About Aira Project",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                "Credits, technology documentation & license info",
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: Color(0xFF5C2219),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Language Selection dialog popup
  void _showLanguageSelector(
    BuildContext context,
    NavigationProvider provider,
  ) {
    final languages = [
      "English (US)",
      "English (UK)",
      "Hindi (IN)",
      "Spanish (ES)",
      "German (DE)",
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Select Voice Language"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final lang = languages[index];
                return ListTile(
                  title: Text(
                    lang,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: provider.voiceLanguage == lang
                      ? const Icon(Icons.check, color: Color(0xFF5C2219))
                      : null,
                  onTap: () {
                    provider.setVoiceLanguage(lang);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Voice readout language changed to $lang",
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Emergency contact editor dialog modal
  void _showEmergencyContactDialog(
    BuildContext context,
    NavigationProvider provider,
  ) {
    final controller = TextEditingController(text: provider.emergencyContact);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Update Caretaker Contact"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Urgent notifications and cellular SOS SMS will route to this phone number:",
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.3),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: "Phone Number",
                  hintText: "+1 (555) 000-0000",
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(80, 42)),
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  provider.updateEmergencyContact(controller.text);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Emergency SOS contact number saved."),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text("Save Number"),
            ),
          ],
        );
      },
    );
  }

  // Factory reset verification warning dialog
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text("Factory Reset Stick?"),
          content: const Text(
            "WARNING: This action sends an EEPROM format signal over Bluetooth. All cached calibration models, obstacle limits, and sound banks will be erased. Proceed?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Abort"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD90429),
                minimumSize: const Size(80, 42),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Formatting device EEPROM... Reset command dispatched.",
                    ),
                    backgroundColor: Color(0xFFD90429),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("Format memory"),
            ),
          ],
        );
      },
    );
  }
}
