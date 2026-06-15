// Web-only implementation — compiled only when dart.library.html is present.
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html; // dart:html still works; package:web not yet in pubspec

void requestCallFullscreen() {
  try {
    // Request browser fullscreen so the call occupies the entire screen
    // including hiding the address bar and browser chrome.
    html.document.documentElement?.requestFullscreen();
  } catch (_) {
    // Some browsers (e.g. Safari) block fullscreen outside a direct gesture
    // handler.  Fail silently — the call still works without fullscreen.
  }
}

void exitCallFullscreen() {
  try {
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    }
  } catch (_) {}
}
