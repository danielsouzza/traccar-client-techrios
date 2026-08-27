import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/models.dart';
import 'api/rastreio_api.dart';
import 'geolocation_service.dart';
import 'preferences.dart';

/// Sessão do usuário na API de rastreio.
///
/// O token fica no armazenamento seguro do sistema; a seleção de empresa e
/// embarcação fica nas preferências comuns, por não ser sensível.
class SessionService {
  SessionService._();

  static const _tokenKey = 'rastreio_token';
  static const _storage = FlutterSecureStorage();

  static String? _token;
  static Perfil? perfil;

  /// Observado pelo gate de autenticação para trocar entre login e app.
  static final ValueNotifier<bool> signedIn = ValueNotifier<bool>(false);

  static String? get token => _token;

  static Future<void> init() async {
    try {
      _token = await _storage.read(key: _tokenKey);
    } catch (error) {
      developer.log('Failed to read session token', error: error);
      _token = null;
    }
    signedIn.value = _token != null && _token!.isNotEmpty;
  }

  static Future<void> signIn(LoginResult result) async {
    _token = result.token;
    perfil = result.perfil;
    await Preferences.instance.setString(Preferences.usuarioNome, result.perfil.name);
    await _storage.write(key: _tokenKey, value: result.token);
    signedIn.value = true;
  }

  /// Revoga o token no servidor quando possível, mas sempre limpa o local —
  /// o usuário não pode ficar preso numa sessão por causa de falha de rede.
  static Future<void> signOut() async {
    final current = _token;
    if (current != null && current.isNotEmpty) {
      try {
        await RastreioApi.logout(current);
      } catch (error) {
        developer.log('Failed to revoke token', error: error);
      }
    }
    _token = null;
    perfil = null;
    try {
      await _storage.delete(key: _tokenKey);
    } catch (error) {
      developer.log('Failed to delete session token', error: error);
    }
    await clearEmbarcacao();
    signedIn.value = false;
  }

  // --- Seleção atual -------------------------------------------------------

  static String? get empresaNome => Preferences.instance.getString(Preferences.empresaNome);
  static int? get empresaId => Preferences.instance.getInt(Preferences.empresaId);
  static String? get embarcacaoNome => Preferences.instance.getString(Preferences.embarcacaoNome);
  static String? get usuarioNome => Preferences.instance.getString(Preferences.usuarioNome);
  static int? get embarcacaoId => Preferences.instance.getInt(Preferences.embarcacaoId);

  static bool get hasEmbarcacao => embarcacaoId != null;

  static Future<void> setEmpresa(Empresa empresa) async {
    await Preferences.instance.setInt(Preferences.empresaId, empresa.id);
    await Preferences.instance.setString(Preferences.empresaNome, empresa.displayName);
  }

  /// Aplica a embarcação escolhida: o identificador do Traccar passa a ser o
  /// `traccar_device_id` dela. Se o rastreamento estiver ativo, a troca vale
  /// na hora, sem parar o serviço.
  static Future<void> setEmbarcacao(Embarcacao embarcacao) async {
    final deviceId = embarcacao.traccarDeviceId;
    if (deviceId == null || deviceId.isEmpty) {
      throw StateError('Embarcação sem traccar_device_id');
    }
    await Preferences.instance.setInt(Preferences.embarcacaoId, embarcacao.id);
    await Preferences.instance.setString(Preferences.embarcacaoNome, embarcacao.nome);
    await Preferences.instance.setString(Preferences.id, deviceId);
    final empresa = embarcacao.empresa;
    if (empresa != null) await setEmpresa(empresa);
    await GeolocationService.tracker.setConfig(Preferences.buildConfig());
  }

  static Future<void> clearEmbarcacao() async {
    await Preferences.instance.remove(Preferences.embarcacaoId);
    await Preferences.instance.remove(Preferences.embarcacaoNome);
    await Preferences.instance.remove(Preferences.empresaId);
    await Preferences.instance.remove(Preferences.empresaNome);
    await Preferences.instance.remove(Preferences.usuarioNome);
  }
}
