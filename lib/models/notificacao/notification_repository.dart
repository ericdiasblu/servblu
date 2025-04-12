import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notificacao/notificacao.dart';

class NotificacaoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para listar notificações de um usuário
  Future<List<Notificacao>> listarNotificacoes(String userId) async {
    final res = await _supabase
        .from('notificacoes')
        .select()
        .eq('id_usuario', userId)
        .order('data_envio', ascending: false);
    return (res as List)
        .map((m) => Notificacao.fromMap(m))
        .toList();
  }

  Future<void> saveNotificacao(Notificacao n) async {
    await _supabase.from('notificacoes').insert(n.toMap());
  }

  Future<void> excluirNotificacoes(int id) async {
    await _supabase
        .from('notificacoes')
        .delete()
        .eq('id', id);
  }
}

