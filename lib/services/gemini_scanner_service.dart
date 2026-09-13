import 'dart:convert';
import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

class GeminiScannerService {
  static const String _apiKey = 'AQ.Ab8RN6IvjKeNeTXdVXLZkcUFP12cPGsXky8c_gCDAV2NmytF8g';

  Future<Map<String, dynamic>> scanMedicinePackage(XFile imageFile) async {
    try {
      final Uint8List bytes = await imageFile.readAsBytes();
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );

      final prompt = TextPart(
        'Analyze this medicine packaging image. Extract the information strictly as a JSON object with these keys: '
        '"name" (string), "category" (string e.g. Painkiller, Antibiotic, Vitamin), "active_ingredient" (string), '
        '"storage" (string), "pills" (integer estimate, 0 if unknown), "frequency" (integer per day). '
        'Return only raw JSON without markdown or explanations.',
      );

      final imagePart = DataPart('image/jpeg', bytes);
      final response = await model.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '{}';
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
}
