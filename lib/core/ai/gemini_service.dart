import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'parsed_transaction.dart';

/// Fallo de la llamada a Gemini con un mensaje presentable.
class GeminiException implements Exception {
  GeminiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GeminiService {
  GeminiService()
    : _dio = Dio(
        BaseOptions(
          // Sin timeouts, una red que no responde deja el botón "Analizando…"
          // colgado para siempre.
          connectTimeout: const Duration(seconds: 15),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

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
    if (key == null || key.isEmpty) {
      throw GeminiException(
        'Configura tu API key de Gemini en Ajustes → Inteligencia Artificial.',
      );
    }

    final Response<dynamic> res;
    try {
      res = await _dio.post(
        '$_endpoint?key=$key',
        data: {
          'contents': [
            {'parts': parts},
          ],
          'generationConfig': {'responseMimeType': 'application/json'},
        },
      );
    } on DioException catch (error) {
      throw GeminiException(_messageFor(error));
    }

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

  /// Traduce el fallo de red a algo accionable. Dio imprime su propio texto
  /// para cada código HTTP y para el 429 dice "the request contains bad
  /// syntax", que despista: el 429 es límite de uso, no una petición mal
  /// formada.
  String _messageFor(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Gemini tardó demasiado en responder. Inténtalo de nuevo.';
      case DioExceptionType.connectionError:
        return 'Sin conexión con Gemini. Revisa tu internet.';
      case DioExceptionType.cancel:
        return 'Se canceló la consulta a Gemini.';
      default:
        break;
    }

    final status = error.response?.statusCode;
    return switch (status) {
      429 =>
        'Alcanzaste el límite de uso de Gemini. Espera unos minutos e '
            'inténtalo otra vez, o revisa la cuota de tu cuenta.',
      400 =>
        'Gemini rechazó la petición. Si acabas de pegar la API key, '
            'revisa que esté completa.',
      401 || 403 =>
        'Tu API key de Gemini no es válida o no tiene permisos. '
            'Revísala en Ajustes → Inteligencia Artificial.',
      404 =>
        'El modelo de Gemini no está disponible para tu cuenta.',
      500 || 502 || 503 || 504 =>
        'Gemini no está disponible en este momento. Inténtalo más tarde.',
      _ => 'No se pudo conectar con Gemini${status == null ? '' : ' ($status)'}.',
    };
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
