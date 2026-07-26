import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'parsed_transaction.dart';

class GeminiService {
  GeminiService() : _dio = Dio();

  static const _storage = FlutterSecureStorage();
  static const _apiKeyName = 'gemini_api_key';
  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final Dio _dio;

  static Future<String?> getApiKey() => _storage.read(key: _apiKeyName);
  static Future<void> saveApiKey(String key) =>
      _storage.write(key: _apiKeyName, value: key);

  Future<ParsedTransaction?> parseFromText(
    String text,
    List<String> categoryNames,
  ) =>
      _call([
        {'text': '${_prompt(categoryNames)}\n\nInput: $text'},
      ]);

  Future<ParsedTransaction?> parseFromImage(
    Uint8List bytes,
    String mimeType,
    List<String> categoryNames,
  ) =>
      _call([
        {'text': _prompt(categoryNames)},
        {
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Encode(bytes),
          },
        },
      ]);

  Future<ParsedTransaction?> _call(
    List<Map<String, dynamic>> parts,
  ) async {
    final key = await getApiKey();
    if (key == null || key.isEmpty) return null;

    final res = await _dio.post(
      '$_endpoint?key=$key',
      data: {
        'contents': [
          {'parts': parts},
        ],
        'generationConfig': {'responseMimeType': 'application/json'},
      },
    );

    try {
      final text =
          res.data['candidates'][0]['content']['parts'][0]['text'] as String;
      return ParsedTransaction.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  String _prompt(List<String> categoryNames) {
    final cats = categoryNames.isEmpty
        ? 'ninguna disponible'
        : categoryNames.join(', ');
    return '''
Eres un parser de movimientos financieros. Extrae datos del input (texto libre o imagen de ticket/recibo) y devuelve SOLO un JSON con estos campos:
- type: "expense", "income" o "transfer"
- amount: número con hasta 2 decimales (ej: 350.50)
- description: descripción corta, máximo 80 caracteres
- categoryName: una de [$cats] que mejor aplique, o null si ninguna encaja
- date: fecha ISO YYYY-MM-DD si se menciona claramente, o null
- note: detalle adicional útil, o null

Solo el objeto JSON, sin markdown ni explicación.''';
  }
}
