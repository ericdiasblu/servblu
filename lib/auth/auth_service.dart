import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cadastro com email e senha (apenas cria o usuário no auth)
  Future<AuthResponse> signUpWithEmailPassword(
      String email, String password, String name, String phone, String address) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Atualiza os detalhes do usuário na tabela 'usuarios'
  // newPassword é opcional (para update de senha em outra situação)
  Future<void> updateUserDetails(String userId, String email, String name, String phone, String address, String? newPassword) async {
    // Atualiza a senha somente se for realmente desejado atualizar (em cadastro, passamos null)
    if (newPassword != null && newPassword.isNotEmpty) {
      final passwordResponse = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      if (passwordResponse.user == null) {
        throw Exception('Erro ao atualizar a senha.');
      }
    }

    // Insere (ou atualiza) os dados extras na tabela 'usuarios'
    final response = await _supabase.from('usuarios').upsert({
      'id_usuario': userId, // Certifique-se de que esta coluna exista na tabela
      'nome': name,
      'telefone': phone,
      'endereco': address,
      'email': email,
    });

    if (response.error != null) {
      throw Exception('Erro ao atualizar os detalhes do usuário: ${response.error!.message}');
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
