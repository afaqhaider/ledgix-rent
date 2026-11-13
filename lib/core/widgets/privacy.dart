import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common.dart';

/// Public privacy policy (Firebase Hosting, web/privacy/index.html).
const privacyPolicyUrl = 'https://rent.getledgix.com/privacy';

/// Opens the policy in the browser, at the Arabic section in Arabic.
Future<void> openPrivacyPolicy(BuildContext context) {
  final ar = Localizations.localeOf(context).languageCode == 'ar';
  return launchUrl(Uri.parse(ar ? '$privacyPolicyUrl#ar' : privacyPolicyUrl), mode: LaunchMode.externalApplication);
}

/// Small "Privacy policy" text link for the login screen.
class PrivacyPolicyLink extends StatelessWidget {
  const PrivacyPolicyLink({super.key});

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: () => openPrivacyPolicy(context),
          child: Text(context.l.privacyPolicy),
        ),
      );
}
