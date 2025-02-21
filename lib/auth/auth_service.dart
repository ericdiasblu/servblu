import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cadastro com email e senha
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password, String name, String phone, String address) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Atualizar detalhes do usuário, incluindo senha
  Future<void> updateUserDetails(String name, String phone, String address, String? password) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Se a senha não for nula, atualiza a senha do usuário
      if (password != null && password.isNotEmpty) {
        final passwordResponse = await _supabase.auth.updateUser(UserAttributes(password: password));
        // Verifica se o update retornou um usuário atualizado
        if (passwordResponse.user == null) {
          throw Exception('Erro ao atualizar a senha.');
        }
      }

      // Atualiza os detalhes do usuário na tabela 'usuarios'
      final response = await _supabase.from('usuarios').upsert({
        'id_usuario': user.id, // Vincula os dados ao usuário autenticado
        'nome': name,
        'telefone': phone,
        'endereco': address,
        'email': user.email, // Utiliza o e-mail do usuário autenticado
      });

      if (response.error != null) {
        throw Exception('Erro ao atualizar os detalhes do usuário: ${response.error!.message}');
      }
    }
  }

  // Entrar com email e senha
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sair da conta
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Obter o email do usuário atual
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
