import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrHelper {
  static Future<List<Map<String, dynamic>>> scanReceipt({
    ImageSource source = ImageSource.camera,
  }) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image == null) return [];

    final inputImage = InputImage.fromFilePath(image.path);
    final textRecognizer = TextRecognizer();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parseReceiptText(recognizedText.text);
    } finally {
      await textRecognizer.close();
    }
  }

  static List<Map<String, dynamic>> _parseReceiptText(String text) {
    final items = <Map<String, dynamic>>[];
    final lines = text.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Pattern: "Item name   123" or "Item name 123.45"
      final match = RegExp(r'^(.+?)\s+(\d+[.,]?\d*)\s*$').firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1)!.trim();
        final priceStr = match.group(2)!.replaceAll(',', '.');
        final price = double.tryParse(priceStr);

        if (price != null && price > 0 && name.length > 1) {
          // Skip lines that look like dates, phone numbers, etc.
          if (RegExp(r'^\d{2}[./]\d{2}').hasMatch(name)) continue;
          if (name.contains('+') || name.contains('tel')) continue;

          items.add({'name': name, 'price': price});
        }
      }
    }

    return items;
  }
}
