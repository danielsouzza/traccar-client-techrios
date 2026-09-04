import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import 'l10n/app_localizations.dart';
import 'theme.dart';
import 'update_service.dart';

/// Oferece a atualização e acompanha o download até o instalador do Android
/// assumir. A atualização é opcional: o usuário pode adiar e seguir usando.
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, required this.versao});

  final VersaoDisponivel versao;

  static Future<void> mostrar(BuildContext context, VersaoDisponivel versao) {
    return showDialog<void>(
      context: context,
      // Enquanto não baixa, tocar fora fecha — adiar tem de ser fácil.
      barrierDismissible: true,
      builder: (_) => UpdateDialog(versao: versao),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  StreamSubscription<OtaEvent>? _inscricao;
  double? _progresso;
  String? _erro;

  @override
  void dispose() {
    _inscricao?.cancel();
    super.dispose();
  }

  void _atualizar() {
    final localizations = AppLocalizations.of(context)!;
    setState(() {
      _progresso = 0;
      _erro = null;
    });
    _inscricao = UpdateService.baixarEInstalar(widget.versao).listen(
      (evento) {
        if (!mounted) return;
        switch (evento.status) {
          case OtaStatus.DOWNLOADING:
            final pct = double.tryParse(evento.value ?? '');
            setState(() => _progresso = pct == null ? null : pct / 100);
          case OtaStatus.INSTALLING:
            // O instalador do Android assumiu; o diálogo já cumpriu o papel.
            Navigator.of(context).maybePop();
          default:
            setState(() {
              _progresso = null;
              _erro = localizations.updateFailed;
            });
        }
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _progresso = null;
          _erro = localizations.updateFailed;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = context.palette;
    final baixando = _progresso != null;

    return AlertDialog(
      title: Text(localizations.updateAvailableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(localizations.updateAvailableMessage),
          const SizedBox(height: 6),
          Text(
            'v${widget.versao.versionName}',
            style: TextStyle(fontSize: 13, color: palette.textSecondary),
          ),
          if (baixando) ...[
            const SizedBox(height: 18),
            LinearProgressIndicator(value: _progresso == 0 ? null : _progresso),
            const SizedBox(height: 8),
            Text(
              localizations.updateDownloading,
              style: TextStyle(fontSize: 13, color: palette.textSecondary),
            ),
          ],
          if (_erro != null) ...[
            const SizedBox(height: 14),
            Text(
              _erro!,
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13.5),
            ),
          ],
        ],
      ),
      actions: baixando
          ? null
          : [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.updateLaterButton),
              ),
              TextButton(
                onPressed: _atualizar,
                child: Text(localizations.updateNowButton),
              ),
            ],
    );
  }
}
