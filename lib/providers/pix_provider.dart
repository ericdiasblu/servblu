import 'package:flutter/foundation.dart';
import '../models/pagamento/pix_charge.dart';
import '../models/pagamento/pix_qrcode.dart';
import '../services/pagamento_service.dart';

class PixProvider with ChangeNotifier {
  final PixService _pixService = PixService();

  PixCharge? _currentCharge;
  PixQRCode? _currentQRCode;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _withdrawalResult; // NOVA VARIAVEL

  PixCharge? get currentCharge => _currentCharge;
  PixQRCode? get currentQRCode => _currentQRCode;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get withdrawalResult => _withdrawalResult; // NOVA VARIAVEL


  // Método para criar uma nova cobrança PIX
  Future<void> createCharge({
    required double? amount,
    required String description,
    int expiresIn = 3600,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {

      // Validate amount
      if (amount == null) {
        throw Exception('O valor do pagamento não pode ser nulo');
      }

      if (amount < 1) {
        throw Exception('O valor mínimo para pagamento PIX é R\$ 1,00');
      }

      // Cria a cobrança
      final charge = await _pixService.createCharge(
        amount: amount,
        description: description,
        expiresIn: expiresIn,
      );
      _currentCharge = charge;

      // Gera o QR Code
      final qrCode = await _pixService.generateQRCode(charge.locationId);
      _currentQRCode = qrCode;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Verificar status de uma cobrança
  Future<void> checkChargeStatus(String txid) async {
    _isLoading = true;
    notifyListeners();

    try {
      final charge = await _pixService.getCharge(txid);
      _currentCharge = charge;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

// NOVO METODO
  // Método para realizar um saque (withdrawal)
  Future<Map<String, dynamic>> createWithdrawal({
    required double amount,
    required String pixKey,
    required String pixKeyType,
    String description = 'Saque',

  }) async {
    _isLoading = true;
    _error = null;
    _withdrawalResult = null;
    notifyListeners();

    try {
      // Validações básicas
      if (amount < 1) {
        throw Exception('O valor mínimo para saque é R\$ 1,00');
      }

      // Chama o serviço de saque
      final result = await _pixService.createWithdrawal(
        amount: amount,
        pixKey: pixKey,
        pixKeyType: pixKeyType,
        description: description,
      );
      
      _withdrawalResult = result;
      _isLoading = false;
      notifyListeners();
      
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Limpa os dados atuais
  void clear() {
    _currentCharge = null;
    _currentQRCode = null;
    _withdrawalResult = null; // NOVO CLEAR
    _error = null;
    notifyListeners();
  }
}