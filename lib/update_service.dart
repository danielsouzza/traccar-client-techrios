import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'app_info.dart';

/// Versão publicada, lida do manifesto que acompanha a release.
class VersaoDisponivel {
  const VersaoDisponivel({
    required this.versionCode,
    required this.versionName,
    required this.url,
  });

  final int versionCode;
  final String versionName;
  final String url;
}

/// Descobre se há uma versão mais nova publicada fora da loja.
///
/// Só compara: quem baixa e instala é o próprio Android, quando o app abre a
/// URL do APK no navegador. Baixar de dentro do app, via ota_update, derrubava
/// o processo no meio do download e nunca chegava a instalar.
///
/// Como o APK é assinado com a mesma chave, ele substitui o instalado sem
/// desinstalar, preservando sessão e embarcação selecionada.
class UpdateService {
  UpdateService._();

  /// Endereço do manifesto. Sai de `--dart-define` para o dia em que o
  /// repositório fechar ou o APK mudar de hospedagem.
  static const String manifestUrl = String.fromEnvironment(
    'RASTREIO_UPDATE_URL',
    defaultValue:
        'https://github.com/danielsouzza/traccar-client-techrios/releases/latest/download/latest.json',
  );

  static const Duration _timeout = Duration(seconds: 15);

  /// Devolve a versão publicada quando ela é mais nova que a instalada.
  ///
  /// Nunca lança: a checagem é conveniência, e uma falha de rede não pode
  /// atrapalhar quem só quer abrir o app e rastrear.
  static Future<VersaoDisponivel?> verificar() async {
    if (manifestUrl.isEmpty) return null;
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final request = await client.getUrl(Uri.parse(manifestUrl)).timeout(_timeout);
      final response = await request.close().timeout(_timeout);
      if (response.statusCode != HttpStatus.ok) return null;
      final texto = await response.transform(utf8.decoder).join();
      final dados = jsonDecode(texto) as Map<String, dynamic>;

      final publicada = int.tryParse('${dados['versionCode']}') ?? 0;
      final instalada = int.tryParse(AppInfo.buildNumber) ?? 0;
      if (publicada <= instalada) return null;

      final url = dados['url']?.toString();
      if (url == null || url.isEmpty) return null;

      return VersaoDisponivel(
        versionCode: publicada,
        versionName: dados['versionName']?.toString() ?? '',
        url: url,
      );
    } catch (error) {
      developer.log('Falha ao verificar atualização', error: error);
      return null;
    } finally {
      client.close();
    }
  }
}
