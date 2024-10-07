import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:friend_private/backend/preferences.dart';
import 'package:friend_private/pages/facts/page.dart';
import 'package:friend_private/pages/settings/change_name_widget.dart';
import 'package:friend_private/pages/settings/privacy.dart';
import 'package:friend_private/pages/settings/recordings_storage_permission.dart';
import 'package:friend_private/pages/speech_profile/page.dart';
import 'package:friend_private/utils/analytics/mixpanel.dart';
import 'package:friend_private/utils/other/temp.dart';
import 'package:friend_private/widgets/dialog.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
        child: ListView(
          children: <Widget>[
            // getItemAddOn('Identifying Others', () {
            //   routeToPage(context, const UserPeoplePage());
            // }, icon: Icons.people),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
              title: Text(
                  SharedPreferencesUtil().givenName.isEmpty
                      ? 'About YOU'
                      : 'About ${SharedPreferencesUtil().givenName.toUpperCase()}',
                  style: const TextStyle(color: Colors.white)),
              subtitle: const Text('What Foxxy has learned about you 👀'),
              trailing: const Icon(Icons.self_improvement, size: 20),
              onTap: () {
                routeToPage(context, const FactsPage());
                MixpanelManager().pageOpened('Profile Facts');
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
              title: const Text('Speech Profile', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Teach Foxxy your voice'),
              trailing: const Icon(Icons.multitrack_audio, size: 20),
              onTap: () {
                routeToPage(context, const SpeechProfilePage());
                MixpanelManager().pageOpened('Profile Speech Profile');
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
              title: Text(
                SharedPreferencesUtil().givenName.isEmpty ? 'Set Your Name' : 'Change Your Name',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(SharedPreferencesUtil().givenName.isEmpty ? 'Not set' : SharedPreferencesUtil().givenName),
              trailing: const Icon(Icons.person, size: 20),
              onTap: () async {
                MixpanelManager().pageOpened('Profile Change Name');
                await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return const ChangeNameWidget();
                  },
                ).whenComplete(() => setState(() {}));
              },
            ),
            const SizedBox(height: 24),
            Divider(color: Colors.grey.shade300, height: 1),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
              title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
              trailing: const Icon(
                Icons.warning,
                size: 20,
              ),
              onTap: () {
                MixpanelManager().pageOpened('Profile Delete Account Dialog');
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: Text(
                        'Please send an SMS at 13510279525 with account ID to delete your account',
                        style: TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    );
                  },
                );
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.fromLTRB(4, 0, 24, 0),
              title: const Text('Your User Id', style: TextStyle(color: Colors.white)),
              subtitle: Text(SharedPreferencesUtil().uid),
              trailing: const Icon(Icons.copy_rounded, size: 20, color: Colors.white),
              onTap: () {
                MixpanelManager().pageOpened('Authorize Saving Recordings');
                Clipboard.setData(ClipboardData(text: SharedPreferencesUtil().uid));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UID copied to clipboard')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
