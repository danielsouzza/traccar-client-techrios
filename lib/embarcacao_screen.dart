import 'package:flutter/material.dart';

import 'api/models.dart';
import 'api/rastreio_api.dart';
import 'geolocation_service.dart';
import 'l10n/app_localizations.dart';
import 'main.dart';
import 'paginated_list.dart';
import 'session_service.dart';
import 'theme.dart';

/// Lista as embarcações e aplica a escolhida como identificador do Traccar.
/// Devolve `true` ao ser fechada quando houve seleção.
class EmbarcacaoScreen extends StatelessWidget {
  const EmbarcacaoScreen({super.key, this.empresaId, this.showBackButton = true});

  /// Só tem efeito para perfil Master; Empresa já vem filtrado pelo servidor.
  final int? empresaId;

  /// Falso na primeira seleção após o login, quando não há para onde voltar.
  final bool showBackButton;

  Future<void> _select(BuildContext context, Embarcacao embarcacao) async {
    final localizations = AppLocalizations.of(context)!;
    final wasTracking = await GeolocationService.tracker.isTracking();
    // Avisa o servidor que a embarcação anterior deixou de ser monitorada.
    // Precisa vir antes do setEmbarcacao, que troca o identificador enviado.
    if (wasTracking && SessionService.hasEmbarcacao) {
      await GeolocationService.reportTrackingStopped();
    }
    await SessionService.setEmbarcacao(embarcacao);
    messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          wasTracking ? localizations.vesselChangedMessage : localizations.vesselAppliedMessage,
        ),
      ),
    );
    if (context.mounted) Navigator.pop(context, true);
  }

  Widget _buildTile(BuildContext context, Embarcacao embarcacao) {
    final palette = context.palette;
    final localizations = AppLocalizations.of(context)!;
    final selectable = embarcacao.selecionavel;
    final selected = SessionService.embarcacaoId == embarcacao.id;
    final subtitle = embarcacao.empresa?.displayName ??
        (selectable ? embarcacao.traccarDeviceId! : localizations.notProvisionedLabel);

    return Opacity(
      opacity: selectable ? 1 : 0.55,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: selectable ? () => _select(context, embarcacao) : null,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? palette.primary : palette.borderCard,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: palette.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      selected ? Icons.check : Icons.directions_boat,
                      size: 22,
                      color: palette.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          embarcacao.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.5, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (selectable)
                    Icon(Icons.chevron_right, color: palette.muted, size: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final palette = context.palette;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(showBackButton ? 4 : 20, 12, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showBackButton)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.vesselTitle,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          localizations.vesselListSubtitle,
                          style: TextStyle(fontSize: 13, color: palette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PaginatedList<Embarcacao>(
                  loader: (page, _) => RastreioApi.embarcacoes(
                    SessionService.token ?? '',
                    empresaId: empresaId,
                    page: page,
                  ),
                  // A API não oferece busca em /embarcacoes, então o filtro é
                  // local, sobre as páginas já carregadas.
                  localFilter: (embarcacao, query) {
                    final term = query.toLowerCase();
                    return embarcacao.nome.toLowerCase().contains(term) ||
                        (embarcacao.empresa?.displayName.toLowerCase().contains(term) ?? false) ||
                        (embarcacao.traccarDeviceId?.toLowerCase().contains(term) ?? false);
                  },
                  onUnauthorized: SessionService.signOut,
                  itemBuilder: _buildTile,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
