import 'package:intl/intl.dart';

class DateHelper {
  // Dias da semana em português
  static const List<String> diasSemana = [
    'Segunda-feira', // index 0 corresponde a DateTime.weekday == 1
    'Terça-feira',   // index 1 corresponde a DateTime.weekday == 2
    'Quarta-feira',  // index 2 corresponde a DateTime.weekday == 3
    'Quinta-feira',  // index 3 corresponde a DateTime.weekday == 4
    'Sexta-feira',   // index 4 corresponde a DateTime.weekday == 5
    'Sábado',        // index 5 corresponde a DateTime.weekday == 6
    'Domingo'
  ];

  // Converte uma data para o dia da semana em português
  static String obterDiaSemana(DateTime data) {
    return diasSemana[data.weekday % 7];
  }

  // Converte formato de data do banco (DDMM) para DateTime
  static DateTime converterStringParaData(String dataString, int ano) {
    if (dataString.length != 4) {
      throw FormatException('Formato de data inválido. Use DDMM.');
    }

    int dia = int.parse(dataString.substring(0, 2));
    int mes = int.parse(dataString.substring(2, 4));

    return DateTime(ano, mes, dia);
  }

  // Converte DateTime para formato do banco (DDMM)
  static String converterDataParaString(DateTime data) {
    return DateFormat('ddMM').format(data);
  }

  // Formata horário de inteiro para exibição (ex: 1430 -> 14:30)
  static String formatarHorario(int horario) {
    String horarioStr = horario.toString().padLeft(4, '0');
    return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
  }

  // Converte horário de exibição para inteiro (ex: 14:30 -> 1430)
  static int converterStringParaHorario(String horarioString) {
    String sanitized = horarioString.replaceAll(':', '');
    return int.parse(sanitized);
  }

  // Verifica se uma data já passou
  static bool dataPassou(DateTime data) {
    final hoje = DateTime.now();
    return data.year < hoje.year ||
        (data.year == hoje.year && data.month < hoje.month) ||
        (data.year == hoje.year && data.month == hoje.month && data.day < hoje.day);
  }
}