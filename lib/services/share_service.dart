import 'dart:io';
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
      // We use a ProviderScope to ensure the widget can access providers if it's a ConsumerWidget
      final imageBuffer = await _screenshotController.captureFromWidget(
        Material(child: snapshotWidget),
        delay: const Duration(milliseconds: 300), // Slightly more delay for images to load
        context: context,
        pixelRatio: 2.0, // Higher resolution for sharing
      );

      // Save to a temporary file
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/valora_snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBuffer);

      // Share using the share_plus package
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(imagePath)],
        text: 'Check out my Valora collection valuation!',
        sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
      );

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
