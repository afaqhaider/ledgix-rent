import 'package:web/web.dart' as web;

const _verifierKey = 'ledgix_rent_hub_verifier';
const _stateKey = 'ledgix_rent_hub_state';

void saveHubWebFlow(String verifier, String state) {
  web.window.sessionStorage.setItem(_verifierKey, verifier);
  web.window.sessionStorage.setItem(_stateKey, state);
}

({String verifier, String state})? readHubWebFlow() {
  final verifier = web.window.sessionStorage.getItem(_verifierKey);
  final state = web.window.sessionStorage.getItem(_stateKey);
  if (verifier == null || state == null) return null;
  return (verifier: verifier, state: state);
}

void clearHubWebFlow() {
  web.window.sessionStorage.removeItem(_verifierKey);
  web.window.sessionStorage.removeItem(_stateKey);
}

void navigateTo(String url) => web.window.location.href = url;

/// Swaps the callback URL for the app's own root (its `<base href>`, e.g.
/// /app/) without reloading, dropping the one-time code from the address bar.
void replaceUrlWithAppRoot() =>
    web.window.history.replaceState(null, '', Uri.parse(web.document.baseURI).path);
