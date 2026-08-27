// Modelos da API de rastreio. O parse é defensivo porque o paginador do
// Laravel devolve alguns numéricos como string dependendo do driver.

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _asString(dynamic value) {
  final text = value?.toString();
  return (text == null || text.isEmpty) ? null : text;
}

class Empresa {
  const Empresa({
    required this.id,
    required this.xnome,
    this.xfant,
    this.empresaId,
    this.isFilial = false,
  });

  final int id;
  final String xnome;
  final String? xfant;
  final int? empresaId;
  final bool isFilial;

  /// Prefere o nome fantasia, que é como a operação chama a empresa.
  String get displayName => xfant ?? xnome;

  factory Empresa.fromJson(Map<String, dynamic> json) {
    return Empresa(
      id: _asInt(json['id']) ?? 0,
      xnome: _asString(json['xnome']) ?? '',
      xfant: _asString(json['xfant']),
      empresaId: _asInt(json['empresa_id']),
      isFilial: json['is_filial'] == true,
    );
  }
}

class Embarcacao {
  const Embarcacao({
    required this.id,
    required this.nome,
    this.empresa,
    this.traccarDeviceId,
    this.traccarNumericId,
    this.provisionado = false,
  });

  final int id;
  final String nome;
  final Empresa? empresa;
  final String? traccarDeviceId;
  final int? traccarNumericId;
  final bool provisionado;

  /// O app só precisa do traccar_device_id: é o uniqueId que ele envia ao
  /// Traccar. O traccar_numeric_id (e portanto a flag [provisionado]) importa
  /// ao backend da TechRios, para consultar posições pela REST API — não vale
  /// bloquear o rastreamento enquanto o sync ainda não resolveu o numérico.
  bool get selecionavel => traccarDeviceId?.isNotEmpty ?? false;

  factory Embarcacao.fromJson(Map<String, dynamic> json) {
    final empresa = json['empresa'];
    return Embarcacao(
      id: _asInt(json['id']) ?? 0,
      nome: _asString(json['nome']) ?? '',
      empresa: empresa is Map<String, dynamic> ? Empresa.fromJson(empresa) : null,
      traccarDeviceId: _asString(json['traccar_device_id']),
      traccarNumericId: _asInt(json['traccar_numeric_id']),
      provisionado: json['provisionado'] == true,
    );
  }
}

class Perfil {
  const Perfil({
    required this.id,
    required this.name,
    required this.email,
    required this.isMaster,
    this.empresa,
    this.empresaIds = const [],
    this.roles = const [],
  });

  final int id;
  final String name;
  final String email;
  final bool isMaster;
  final Empresa? empresa;
  final List<int> empresaIds;
  final List<String> roles;

  factory Perfil.fromJson(Map<String, dynamic> json) {
    final empresa = json['empresa'];
    return Perfil(
      id: _asInt(json['id']) ?? 0,
      name: _asString(json['name']) ?? '',
      email: _asString(json['email']) ?? '',
      isMaster: json['is_master'] == true,
      empresa: empresa is Map<String, dynamic> ? Empresa.fromJson(empresa) : null,
      empresaIds: (json['empresa_ids'] as List?)?.map(_asInt).whereType<int>().toList() ?? const [],
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}

/// Página do paginador do Laravel: itens em data.data, metadados ao lado.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory Paginated.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) {
    final rows = (json['data'] as List?) ?? const [];
    return Paginated<T>(
      items: rows.whereType<Map<String, dynamic>>().map(parse).toList(),
      currentPage: _asInt(json['current_page']) ?? 1,
      lastPage: _asInt(json['last_page']) ?? 1,
      total: _asInt(json['total']) ?? rows.length,
    );
  }
}
