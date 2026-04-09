import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

class ShareService {
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> shareSnapshot(BuildContext context, Widget snapshotWidget) async {
    try {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generating high-res snapshot...'), duration: Duration(seconds: 1)),
      );

      // Capture the widget as a PNG image
      final imageBuffer = await _screenshotController.captureFromWidget(
        Material(child: snapshotWidget),
        delay: const Duration(milliseconds: 500), // Slightly more delay for images to load
        context: context,
        pixelRatio: 2.0, // Higher resolution for sharing
      );

      if (!context.mounted) return;

      final RenderBox? box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null ? box.localToGlobal(Offset.zero) & box.size : null;

      if (kIsWeb) {
        // On Web, we can't use path_provider. Use XFile.fromData directly.
        await Share.shareXFiles(
          [XFile.fromData(imageBuffer, mimeType: 'image/png', name: 'valora_snapshot.png')],
          text: 'Check out my Valora collection valuation!',
          sharePositionOrigin: sharePositionOrigin,
        );
      } else {
        // Save to a temporary file for Native platforms
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/valora_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBuffer);

        // Share using the share_plus package
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: 'Check out my Valora collection valuation!',
          sharePositionOrigin: sharePositionOrigin,
        );
      }

    } catch (e) {
      debugPrint('[ShareService] Error sharing snapshot: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate snapshot: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
