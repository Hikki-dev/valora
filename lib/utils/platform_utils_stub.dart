class PlatformUtils {
  /// Dispatches the 'flutter-first-frame' event on Web.
  /// Does nothing on mobile/desktop platforms.
  static void signalFirstFrame() {
    // No-op for mobile/desktop
  }
}
