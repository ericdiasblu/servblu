// models/disponibilidade.dart
class DiaDisponivel {
  final String idDisponibilidade; // Gerado automaticamente pelo banco
  final String idPrestador;
  final String dia; // Ex.: 'Segunda-feira'

  DiaDisponivel({
    required this.idDisponibilidade,
    required this.idPrestador,
    required this.dia,
  });

  factory DiaDisponivel.fromJson(Map<String, dynamic> json) {
    return DiaDisponivel(
      idDisponibilidade: json['id_disponibilidade'],
      idPrestador: json['id_prestador'],
      dia: json['dia'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_disponibilidade': idDisponibilidade,
      'id_prestador': idPrestador,
      'dia': dia,
    };
  }
}

class HorarioDisponivel {
  final String idDisponibilidade;
  final int horario;

  HorarioDisponivel({
    required this.idDisponibilidade,
    required this.horario,
  });

  factory HorarioDisponivel.fromJson(Map<String, dynamic> json) {
    return HorarioDisponivel(
      idDisponibilidade: json['id_disponibilidade'],
      horario: json['horario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_disponibilidade': idDisponibilidade,
      'horario': horario,
    };
  }
}
