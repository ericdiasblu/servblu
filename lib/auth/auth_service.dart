import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cadastro com email e senha
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // Atualizar detalhes do usuário
  Future<void> updateUserDetails(String name, String phone) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final response = await _supabase.from('usuarios').insert({
        'nome': name,
        'telefone': phone,
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

  // Get user email
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    final user = session?.user;
    return user?.email;
  }
}
