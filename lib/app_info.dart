import 'dart:developer' as developer;

import 'package:package_info_plus/package_info_plus.dart';

/// Metadados do próprio pacote instalado.
///
/// Lidos da plataforma em vez de uma constante no código: assim a versão
/// exibida no login é sempre a do `pubspec.yaml` que gerou o build, sem risco
/// de divergir depois de um release.
class AppInfo {
  AppInfo._();

  static String version = '';

  static Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
    } catch (error) {
      developer.log('Failed to read package info', error: error);
    }
  }
}
