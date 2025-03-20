class Servico {
  final String? idServico; // id_servico no banco agora é UUID
  final String nome; // nome no banco
  final String descricao; // descricao no banco
  final String categoria; // categoria no banco
  final String? imgServico; // img_servico no banco (opcional)
  final double? preco; // preco no banco
  final String idPrestador; // id_prestador no banco (uuid)

  Servico({
    this.idServico,
    required this.nome,
    required this.descricao,
    required this.categoria,
    this.imgServico,
    this.preco,
    required this.idPrestador,
  });

  // Método copyWith
  Servico copyWith({
    String? idServico,
    String? nome,
    String? descricao,
    String? categoria,
    String? imgServico,
    double? preco,
    String? idPrestador,
  }) {
    return Servico(
      idServico: idServico ?? this.idServico,
      nome: nome ?? this.nome,
      descricao: descricao ?? this.descricao,
      categoria: categoria ?? this.categoria,
      imgServico: imgServico ?? this.imgServico,
      preco: preco ?? this.preco,
      idPrestador: idPrestador ?? this.idPrestador,
    );
  }

  // Método fromJson
  factory Servico.fromJson(Map<String, dynamic> json) {
    return Servico(
      idServico: json['id_servico'],
      nome: json['nome'],
      descricao: json['descricao'],
      categoria: json['categoria'],
      imgServico: json['img_servico'],
      preco: json['preco']?.toDouble(),
      idPrestador: json['id_prestador'],
    );
  }

  // Método toJson
  Map<String, dynamic> toJson() {
    return {
      if (idServico != null) 'id_servico': idServico,
      'nome': nome,
      'descricao': descricao,
      'categoria': categoria,
      'img_servico': imgServico, // Sempre inclui, mesmo se for nulo
      if (preco != null) 'preco': preco,
      'id_prestador': idPrestador,
    };
  }
}