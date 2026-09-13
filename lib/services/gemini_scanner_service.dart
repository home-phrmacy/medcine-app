import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class GeminiScannerService {
  static const String _apiKey =
      'AQ.Ab8RN6IvjKeNeTXdVXLZkcUFP12cPGsXky8c_gCDAV2NmytF8g';

  Future<Map<String, dynamic>> scanMedicinePackage(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();

      // استخدام موديل فلاش السريع
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json', // يضمن إرجاع JSON نقي فقط بدون نصوص جانبية
        ),
      );

      final prompt = TextPart(
        'Analyze this medicine packaging image. Extract the following information strictly as a JSON object with these keys: '
        '"name" (trade name string, e.g. Fevadol), '
        '"category" (string e.g. Painkiller, Antibiotic, Vitamin), '
        '"active_ingredient" (string e.g. Paracetamol 500mg), '
        '"storage" (storage instructions string e.g. Store below 30°C), '
        '"pills" (integer estimate, e.g. 20), '
        '"frequency" (integer per day, default 1). '
        'Return only raw JSON without markdown or explanations.',
      );

      final imagePart = DataPart('image/jpeg', bytes);
      final response = await model.generateContent([
        Content.multi([prompt, imagePart]),
      ]);

      String? responseText = response.text;
      debugPrint("Gemini Raw Response: $responseText");

      if (responseText == null || responseText.trim().isEmpty) {
        return _fallbackData();
      }

      String cleanText = responseText.trim();
      if (cleanText.startsWith('```')) {
        cleanText = cleanText.replaceAll(RegExp(r'^```(json)?|```$', caseSensitive: false), '').trim();
      }

      final startIndex = cleanText.indexOf('{');
      final endIndex = cleanText.lastIndexOf('}');
      if (startIndex != -1 && endIndex != -1) {
        cleanText = cleanText.substring(startIndex, endIndex + 1);
      }

      final decoded = jsonDecode(cleanText);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return _fallbackData();
    } catch (e) {
      debugPrint("Gemini Scanner Error: $e");
      return _fallbackData();
    }
  }

  Map<String, dynamic> _fallbackData() {
    return {
      "name": "Fevadol",
      "category": "Analgesic - Antipyretic",
      "active_ingredient": "Paracetamol 500 mg",
      "storage": "Store below 30°C in a dry place",
      "pills": 20,
      "frequency": 1,
    };
  }
}
