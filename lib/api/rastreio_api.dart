import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'models.dart';

/// Erro de API já traduzido para algo exibível ao usuário.
/// [statusCode] 0 significa falha de rede, antes de haver resposta HTTP.
class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class LoginResult {
  const LoginResult(this.token, this.perfil);

  final String token;
  final Perfil perfil;
}

class RastreioApi {
  RastreioApi._();

  static const Duration _timeout = Duration(seconds: 30);

  /// Marca as linhas de log para filtrar no Logcat. Só em debug: corpo de
  /// requisição nunca é registrado, porque o login carrega a senha.
  static const String _logTag = 'RastreioApi';

  static void _log(String message) {
    // debugPrint, e não developer.log: só o stdout chega ao logcat (tag
    // "flutter"); developer.log fica restrito ao VM service / DevTools.
    if (kDebugMode) debugPrint('[$_logTag] $message');
  }

  static Uri _uri(String path, [Map<String, dynamic>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.basePath}$path');
    if (query == null) return uri;
    final params = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return params.isEmpty ? uri : uri.replace(queryParameters: params);
  }

  static String _fallbackMessage(int status) {
    return switch (status) {
      401 => 'Sessão expirada. Entre novamente.',
      403 => 'Seu perfil não tem permissão para esta operação.',
      422 => 'Dados inválidos.',
      429 => 'Muitas tentativas. Aguarde um minuto e tente de novo.',
      _ => 'Falha na comunicação com o servidor ($status).',
    };
  }

  /// Executa a requisição e devolve o conteúdo de `data` do envelope.
  static Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.openUrl(method, _uri(path, query)).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set('X-API-KEY', ApiConfig.apiKey);
      if (ApiConfig.hostHeader.isNotEmpty) {
        request.headers.set(HttpHeaders.hostHeader, ApiConfig.hostHeader);
      }
      if (token != null && token.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(_timeout);
      final text = await response.transform(utf8.decoder).join();
      _log('$method ${ApiConfig.basePath}$path -> ${response.statusCode} (${text.length}B)');

      Map<String, dynamic> envelope;
      try {
        envelope = jsonDecode(text) as Map<String, dynamic>;
      } catch (_) {
        // Resposta que não é JSON quase sempre significa que o endereço existe
        // mas não serve a API — tipicamente o HTML da SPA, quando o ambiente
        // aponta para um host onde as rotas não estão publicadas.
        throw ApiException(
          response.statusCode,
          'O endereço configurado não respondeu com a API. Confira o ambiente selecionado.',
        );
      }

      final message = envelope['message']?.toString();
      final ok = response.statusCode >= 200 && response.statusCode < 300 && envelope['success'] == true;
      if (!ok) {
        throw ApiException(
          response.statusCode,
          (message != null && message.isNotEmpty) ? message : _fallbackMessage(response.statusCode),
        );
      }
      return envelope['data'];
    } on ApiException {
      rethrow;
    } on TimeoutException {
      _log('$method $path -> timeout apos ${_timeout.inSeconds}s');
      throw ApiException(0, 'O servidor demorou para responder. Verifique sua conexão.');
    } on SocketException catch (error) {
      _log('$method $path -> falha de rede: ${error.message}');
      throw ApiException(0, 'Sem conexão com o servidor.');
    } on HandshakeException {
      throw ApiException(0, 'Falha na conexão segura com o servidor.');
    } finally {
      client.close();
    }
  }

  static Future<LoginResult> login(String email, String password) async {
    final data = await _send('POST', '/login', body: {
      'email': email,
      'password': password,
    }) as Map<String, dynamic>;
    final token = data['token']?.toString();
    if (token == null || token.isEmpty) {
      throw ApiException(0, 'O servidor não devolveu um token de acesso.');
    }
    return LoginResult(token, Perfil.fromJson(data));
  }

  static Future<Perfil> perfil(String token) async {
    final data = await _send('GET', '/perfil', token: token) as Map<String, dynamic>;
    return Perfil.fromJson(data);
  }

  static Future<void> logout(String token) async {
    await _send('POST', '/logout', token: token);
  }

  /// Restrito a perfil Master; usuário Empresa recebe 403.
  static Future<Paginated<Empresa>> empresas(
    String token, {
    String? busca,
    int page = 1,
    int perPage = 50,
  }) async {
    final data = await _send('GET', '/empresas', token: token, query: {
      'busca': (busca != null && busca.isNotEmpty) ? busca : null,
      'page': page,
      'per_page': perPage,
    }) as Map<String, dynamic>;
    return Paginated.fromJson(data, Empresa.fromJson);
  }

  /// [empresaId] só tem efeito para Master; Empresa já vem filtrado pelo grupo.
  static Future<Paginated<Embarcacao>> embarcacoes(
    String token, {
    int? empresaId,
    int page = 1,
    int perPage = 100,
  }) async {
    final data = await _send('GET', '/embarcacoes', token: token, query: {
      'empresa_id': empresaId,
      'page': page,
      'per_page': perPage,
    }) as Map<String, dynamic>;
    return Paginated.fromJson(data, Embarcacao.fromJson);
  }
}
