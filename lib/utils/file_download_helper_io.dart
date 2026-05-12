import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';

Future<void> downloadFile(Uint8List bytes, String fileName) async {
  try {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(bytes);
        debugPrint('File saved to: ${file.path}');
        return;
      }
    }
    
    // For mobile (Android/iOS) or as a fallback
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  } catch (e) {
    debugPrint('Error saving file: $e');
  }
}
