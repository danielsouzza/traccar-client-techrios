import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:traccar_client_sdk/traccar_client_sdk.dart';

class GeolocationService {
  static final tracker = TraccarClientSdk();

  /// Alarme do protocolo OsmAnd usado para marcar o fim do monitoramento.
  /// `powerOff` é um tipo padrão do Traccar; se o painel da TechRios esperar
  /// outro nome, basta trocar aqui.
  static const String stoppedAlarm = 'powerOff';

  /// Envia uma última posição marcada antes de parar de rastrear.
  ///
  /// Sem isto o servidor apenas deixa de receber posições e só descobre a
  /// ausência por timeout — sem distinguir parada intencional de bateria
  /// acabando, perda de sinal ou app encerrado pelo sistema.
  ///
  /// Deve ser chamado **antes** de trocar a embarcação selecionada, senão o
  /// evento sai com o identificador da embarcação nova.
  ///
  /// O envio avulso não passa pelo buffer: sem rede no momento, o evento se
  /// perde. Por isso a falha não interrompe a parada do rastreamento.
  static Future<void> reportTrackingStopped() async {
    try {
      final delivered = await tracker.requestPosition(alarm: stoppedAlarm);
      if (!delivered) {
        developer.log('Tracking-stopped alarm was not delivered');
      }
    } on PlatformException catch (error) {
      developer.log('Failed to send tracking-stopped alarm', error: error);
    }
  }
}
