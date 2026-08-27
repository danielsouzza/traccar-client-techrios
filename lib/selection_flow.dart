import 'package:flutter/material.dart';

import 'embarcacao_screen.dart';
import 'session_service.dart';

/// Após o login o usuário vai direto para a lista de embarcações.
///
/// Não existe etapa de escolha de empresa: `/embarcacoes` já devolve a frota do
/// grupo para perfil Empresa, e o nome da empresa aparece em cada item — o que
/// também orienta o perfil Master, que enxerga a frota inteira.
class SelectionFlow {
  SelectionFlow._();

  static Future<bool> start(BuildContext context, {bool showBackButton = true}) async {
    final token = SessionService.token;
    if (token == null || token.isEmpty) return false;
    final selected = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => EmbarcacaoScreen(showBackButton: showBackButton),
      ),
    );
    return selected ?? false;
  }
}
