import 'package:web/web.dart' as web;

class PlatformUtils {
  /// Dispatches the 'flutter-first-frame' event on Web.
  static void signalFirstFrame() {
    web.window.dispatchEvent(web.CustomEvent('flutter-first-frame'));
  }
}
