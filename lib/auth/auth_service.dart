import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/router.dart';
import '../services/notification_service.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool isLoggedIn() {
    final session = _supabase.auth.currentSession;
    return session != null && !session.isExpired;
  }

  // Inicializa o estado de autenticação
  void initAuthState() {
    // Define o estado inicial com base na sessão atual
    setLoggedIn(isLoggedIn());

    // Escuta mudanças no estado de autenticação
    _supabase.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      if (event == AuthChangeEvent.signedIn) {
        setLoggedIn(true);
      } else if (event == AuthChangeEvent.signedOut) {
        setLoggedIn(false);
      }
    });
  }

  // Cadastro com email e senha (apenas cria o usuário no auth)
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password, String name, String phone, String address) async {
    // Adicione a manipulação de exceções para capturar erros
    try {
      AuthResponse response = await _supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        setLoggedIn(true);
      }
      return response;
    } catch (e) {
      throw Exception('Erro ao cadastrar usuário: $e');
    }
  }

  // Atualiza os detalhes do usuário
  Future<void> updateUserDetails(String userId, String email, String name, String phone, String address, String? newPassword) async {
    // Atualiza a senha somente se for desejado (em cadastro, passamos null)
    if (newPassword != null && newPassword.isNotEmpty) {
      final passwordResponse = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (passwordResponse.user == null) {
        throw Exception('Erro ao atualizar a senha.');
      }
    }

    // Insere (ou atualiza) os dados extras na tabela 'usuarios'
    // Usamos .select() para forçar o retorno dos dados
    final response = await _supabase
        .from('usuarios')
        .upsert({
      'id_usuario': userId,
      'nome': name,
      'telefone': phone,
      'endereco': address,
      'email': email,
      'saldo': 0,
    })
        .select();

    // Como response é um PostgrestList (uma lista), verificamos se ela está vazia.
    if (response == null || (response is List && response.isEmpty)) {
      throw Exception('A resposta da operação foi nula ou vazia.');
    }
  }

  // Entrar com email e senha
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      AuthResponse response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        setLoggedIn(true);
      }
      return response;
    } catch (e) {
      throw Exception('Erro ao entrar: $e');
    }
  }

  // Sair da conta
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      setLoggedIn(false);
    } catch (e) {
      throw Exception('Erro ao sair: $e');
    }
  }

  // Obter o email do usuário atual
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }

  Future<void> updateFcmTokenAfterLogin() async {
    // Aguardar um pequeno delay para garantir que a sessão esteja completamente estabelecida
    await Future.delayed(const Duration(milliseconds: 500));

    // Verificar se o usuário está realmente autenticado
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Agora podemos com segurança salvar o token
      await NotificationService.saveLocalTokenAfterLogin();
    } else {
      print("Falha ao atualizar token após login: usuário ainda não está autenticado");
    }
  }

  // Adicione este método na classe AuthService
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.appflutter://reset-callback/', // Ajuste para o seu esquema de URL
      );
    } catch (e) {
      throw Exception('Erro ao enviar email de recuperação: $e');
    }
  }
}
