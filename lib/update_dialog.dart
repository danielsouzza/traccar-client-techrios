import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'update_service.dart';

/// Avisa que há versão nova e abre o download no navegador.
///
/// O download embutido, via ota_update, derrubava o app no meio do processo e
/// não chegava a instalar. Abrir o link entrega o mesmo resultado — o Android
/// baixa e oferece instalar — sem permissão de instalar pacotes, sem
/// desugaring e sem plugin capaz de matar o processo.
///
/// A atualização é opcional: dá para adiar e seguir usando.
class UpdateDialog {
  UpdateDialog._();

  static Future<void> mostrar(BuildContext context, VersaoDisponivel versao) {
    final localizations = AppLocalizations.of(context)!;
    final palette = context.palette;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations.updateAvailableTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.updateAvailableMessage),
            const SizedBox(height: 6),
            Text(
              'v${versao.versionName}',
              style: TextStyle(fontSize: 13, color: palette.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(localizations.updateLaterButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await launchUrl(
                  Uri.parse(versao.url),
                  mode: LaunchMode.externalApplication,
                );
              } catch (error) {
                developer.log('Falha ao abrir o download', error: error);
              }
            },
            child: Text(localizations.updateNowButton),
          ),
        ],
      ),
    );
  }
}
