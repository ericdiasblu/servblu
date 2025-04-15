import 'package:intl/intl.dart';

class AgendamentoFormatter {
  static String formatarId(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  static String formatarData(String dataString) {
    try {
      final data = DateTime.parse(dataString);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (e) {
      return dataString;
    }
  }

  static String formatarHorario(dynamic horario) {
    // Se já for string, tenta formatar
    if (horario is String) {
      try {
        int horarioInt = int.parse(horario);
        String horarioStr = horarioInt.toString().padLeft(4, '0');
        return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
      } catch (e) {
        return horario.toString();
      }
    }
    // Se for inteiro, formata diretamente
    else if (horario is int) {
      String horarioStr = horario.toString().padLeft(4, '0');
      return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
    }
    // Qualquer outro tipo, converte para string
    else {
      return horario?.toString() ?? 'N/A';
    }
  }
}