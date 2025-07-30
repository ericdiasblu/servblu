import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
// import 'package:timeago/timeago.dart' as timeago;

import '../../models/notificacao/notificacao.dart';
import '../../models/notificacao/notification_repository.dart';
import '../../router/routes.dart';
import '../../widgets/tool_loading.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificacaoRepository _repository = NotificacaoRepository();
  List<Notificacao> _notificacoes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarNotificacoes();
  }

  Future<void> _carregarNotificacoes() async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        final notificacoes = await _repository.listarNotificacoes(userId);
        setState(() {
          _notificacoes = notificacoes;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar notificações: $e')),
        );
      }
    }
  }

  Future<void> _excluirNotificacao(Notificacao notificacao) async {
    if (notificacao.id != null) {
      try {
        // Adicionar método de exclusão no repositório
        await _repository.excluirNotificacoes(notificacao.id!);

        // Remover da lista local
        setState(() {
          _notificacoes.remove(notificacao);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notificação excluída!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir notificação: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BuildHeader(
            title: 'Notificações',
            backPage: true,
            onBack: () {
              // Use GoRouter to navigate back to profile page
              context.go(Routes.homePage);
            },
            refresh: true,
            onRefresh: _carregarNotificacoes,
          ),
          Expanded(
            child: _isLoading
                ? Center(child:ToolLoadingIndicator(color: Colors.blue, size: 45))
                : _notificacoes.isEmpty
                ? Center(child: Text('Nenhuma notificação encontrada'))
                : ListView.builder(
              itemCount: _notificacoes.length,
              itemBuilder: (context, index) {
                final notificacao = _notificacoes[index];
                return Dismissible(
                  key: Key(notificacao.id.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Mostrar diálogo de confirmação
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Confirmar Exclusão'),
                          content: Text('Deseja realmente excluir esta notificação?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text('Excluir'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _excluirNotificacao(notificacao);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFFEAEAEAFF),
                        child: Image.asset('assets/icon_app.png',width: 28,height: 28,),
                      ),
                      title: Text(
                        notificacao.mensagem,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        timeago.format(notificacao.dataEnvio.toLocal(), locale: 'pt_br'),
                        style: TextStyle(
                          color: notificacao.lida ? Colors.grey : Colors.black,
                        ),
                      ),
                      trailing: notificacao.lida
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}