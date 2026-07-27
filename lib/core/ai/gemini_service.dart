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
  /// Modelo usado para interpretar los movimientos.
  ///
  /// Google va retirando la cuota gratuita de los modelos viejos: cuando eso
  /// pasa la API responde 429 desde la primera consulta, que parece un límite
  /// consumido pero es cuota cero. Si vuelve a ocurrir, se cambia por el
  /// modelo flash vigente; los disponibles para una key se listan en
  /// `GET /v1beta/models`.
  static const model = 'gemini-3.6-flash';

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

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
        _endpoint,
        // La key va en la cabecera, no como `?key=`: es la forma documentada
        // y evita que quede escrita en logs y proxies.
        options: Options(headers: {'x-goog-api-key': key}),
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
      429 => _quotaMessage(error.response?.data),
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

  /// Un 429 puede ser "te pasaste de peticiones por minuto" o "este modelo
  /// tiene cuota cero en tu plan", que se arreglan de formas distintas.
  /// Google lo aclara en `error.details[].violations[].quotaId`.
  String _quotaMessage(Object? body) {
    final quotaId = _quotaId(body);
    if (quotaId != null && quotaId.contains('PerMinute')) {
      return 'Hiciste demasiadas consultas seguidas. Espera un minuto e '
          'inténtalo otra vez.';
    }
    if (quotaId != null && quotaId.contains('PerDay')) {
      return 'Agotaste la cuota diaria de Gemini. Se reinicia a medianoche '
          '(hora del Pacífico).';
    }
    return 'Gemini rechazó la consulta por cuota agotada. Si es de tus '
        'primeras consultas, el modelo no tiene cuota gratuita en tu '
        'proyecto: revísalo en aistudio.google.com.';
  }

  String? _quotaId(Object? body) {
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final details = error['details'];
    if (details is! List) return null;
    for (final detail in details) {
      if (detail is! Map) continue;
      final violations = detail['violations'];
      if (violations is! List) continue;
      for (final violation in violations) {
        if (violation is Map && violation['quotaId'] is String) {
          return violation['quotaId'] as String;
        }
      }
    }
    return null;
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
