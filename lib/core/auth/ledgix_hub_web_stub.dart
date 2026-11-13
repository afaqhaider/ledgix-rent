/// Non-web stand-ins for the browser helpers (never called off the web).
void saveHubWebFlow(String verifier, String state) {}

({String verifier, String state})? readHubWebFlow() => null;

void clearHubWebFlow() {}

void navigateTo(String url) {}

/// Swaps the callback URL for the app's root without reloading.
void replaceUrlWithAppRoot() {}
