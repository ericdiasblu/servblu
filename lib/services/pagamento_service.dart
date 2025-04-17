import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pagamento/pix_charge.dart';
import '../models/pagamento/pix_qrcode.dart';

class PixService {
  // Substitua pela URL do seu backend
  final String baseUrl = 'https://efi-pix-backend.onrender.com/api/pix';

  // Cria uma cobrança PIX
  Future<PixCharge> createCharge({
    required double? amount,
    required String description,
    int expiresIn = 3600,  // 1 hora por padrão
  }) async {

    // Validate amount is not null and at least 1
    if (amount == null || amount < 1) {
      throw Exception('O valor mínimo para pagamento PIX é R\$ 1,00');
    }


    final response = await http.post(
      Uri.parse('$baseUrl/charges'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
      'amount': (amount * 100).toInt(), // Converter para string ao invés de int
        // Ou se o backend espera inteiros, mantenha como está: 'amount': (amount * 100).toInt(),
        'description': description,
        'expiresIn': expiresIn,
      }),
    );

    if (response.statusCode == 201) {
      return PixCharge.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao criar cobrança PIX: ${response.body}');
    }
  }

  // Busca uma cobrança pelo txid
  Future<PixCharge> getCharge(String txid) async {
    final response = await http.get(
      Uri.parse('$baseUrl/charges/$txid'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return PixCharge.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao buscar cobrança PIX: ${response.body}');
    }
  }

  // Gera QR Code para uma cobrança
  Future<PixQRCode> generateQRCode(String locationId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/qrcode/$locationId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return PixQRCode.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Falha ao gerar QR Code: ${response.body}');
    }
  }

  // Listar cobranças com filtros
  Future<List<PixCharge>> listCharges({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
    String? cpf,
    String? cnpj,
    int limit = 100,
  }) async {
    // Formatar datas para o formato ISO
    final startDateFormatted = startDate.toIso8601String();
    final endDateFormatted = endDate.toIso8601String();

    var queryParams = {
      'startDate': startDateFormatted,
      'endDate': endDateFormatted,
      'limit': limit.toString(),
    };

    if (status != null) queryParams['status'] = status;
    if (cpf != null) queryParams['cpf'] = cpf;
    if (cnpj != null) queryParams['cnpj'] = cnpj;

    final uri = Uri.parse('$baseUrl/charges').replace(queryParameters: queryParams);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      final List<dynamic> cobrancas = responseData['cobs'];
      return cobrancas.map((json) => PixCharge.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao listar cobranças PIX: ${response.body}');
    }
  }

  // Reembolsar um PIX
  Future<Map<String, dynamic>> refundPix(String e2eId, {double? amount}) async {
    final Map<String, dynamic> payload = {};
    if (amount != null) {
      payload['amount'] = (amount * 100).toInt();  // Convertendo para centavos
    }

    final response = await http.post(
      Uri.parse('$baseUrl/pix/$e2eId/refund'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao reembolsar PIX: ${response.body}');
    }
  }

  // Obter detalhes de um PIX recebido
  Future<Map<String, dynamic>> getPixDetails(String e2eId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/pix/$e2eId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao obter detalhes do PIX: ${response.body}');
    }
  }
}