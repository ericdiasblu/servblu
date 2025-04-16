import 'package:flutter/material.dart';
// ****** VERIFIQUE SEUS CAMINHOS DE IMPORT ******
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import pode ser necessário dependendo da configuração do seu projeto
// import 'package:supabase/supabase.dart';
// ****** FIM VERIFICAÇÃO CAMINHOS ******


class PaymentStatusScreen extends StatefulWidget {
  final bool successful;
  final String? errorMessage;
  final String txid; // ID da transação PIX (pix_transaction_id)
  final double? valorServico; // Valor a adicionar ao saldo
  final String prestadorId; // ID do usuário prestador
  final String agendamentoId; // ID do agendamento relacionado
  final Agendamento? agendamento; // Objeto agendamento (opcional aqui)

  const PaymentStatusScreen({
    Key? key,
    required this.successful,
    this.errorMessage,
    required this.txid,
    required this.valorServico,
    required this.prestadorId,
    required this.agendamentoId,
    this.agendamento,
  }) : super(key: key);

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  bool _atualizandoSaldo = false;
  bool _saldoAtualizado = false;
  String? _mensagemErroProcessamento; // Erro ocorrido DURANTE o processamento do saldo
  final _supabase = Supabase.instance.client;

  // Lock interno para evitar processamento duplo DENTRO desta instância
  bool _isProcessingSaldo = false;

  @override
  void initState() {
    super.initState();

    // --- DEBUG LOG ---
    // Loga os dados recebidos assim que a tela é criada
    print("--- PaymentStatusScreen initState ---");
    print("TXID: ${widget.txid}");
    print("Successful (PIX Status): ${widget.successful}");
    print("ErrorMessage (from PIX): ${widget.errorMessage}");
    print("Prestador ID: ${widget.prestadorId}");
    print("Agendamento ID: ${widget.agendamentoId}");
    print("Valor Serviço: ${widget.valorServico}");
    print("------------------------------------");
    // --- FIM DEBUG LOG ---

    // Só tenta processar o saldo se o PIX foi confirmado E os IDs essenciais são válidos
    if (widget.successful) {
      // Validação CRUCIAL dos dados recebidos ANTES de iniciar o processamento
      bool dataOk = true;
      String validationError = "";

      // Verifica se os IDs ou valor contém placeholders de erro ou são inválidos
      if (widget.txid.isEmpty || widget.txid.contains("ERRO_")) {
        validationError = "Erro interno: ID da Transação PIX inválido (${widget.txid}).";
        dataOk = false;
      } else if (widget.prestadorId.isEmpty || widget.prestadorId.contains("ERRO_")) {
        validationError = "Erro interno: ID do Prestador inválido (${widget.prestadorId}).";
        dataOk = false;
      } else if (widget.agendamentoId.isEmpty || widget.agendamentoId.contains("ERRO_")) {
        validationError = "Erro interno: ID do Agendamento inválido (${widget.agendamentoId}).";
        dataOk = false;
      } else if (widget.valorServico == null || widget.valorServico! <= 0) {
        validationError = "Erro interno: Valor do serviço inválido (${widget.valorServico}).";
        dataOk = false;
      }

      if (!dataOk) {
        print("ERRO FATAL no initState: $validationError");
        // Define a mensagem de erro para ser exibida no build
        // Usamos _mensagemErroProcessamento para diferenciar de widget.errorMessage
        _mensagemErroProcessamento = validationError;
        _atualizandoSaldo = false; // Garante que não mostre loading
      } else {
        // Dados parecem OK, inicia o processo de atualização do saldo
        print("initState: Dados validados. Chamando _processarAtualizacaoSaldoComLock...");
        _processarAtualizacaoSaldoComLock();
      }
    } else {
      print("initState: Pagamento PIX não foi bem-sucedido (successful=false). Não processando saldo.");
      // O build mostrará o erro vindo do widget.errorMessage
    }
  }

  /// Função de controle com lock interno para a lógica de atualização do saldo.
  Future<void> _processarAtualizacaoSaldoComLock() async {
    // Se já está processando saldo NESTA instância, ignora chamada duplicada.
    if (_isProcessingSaldo) {
      print("Lock Saldo: Ignorando chamada duplicada para _atualizarSaldoPrestador (txid: ${widget.txid})");
      return;
    }
    // Ativa o lock interno
    _isProcessingSaldo = true;
    print("Lock Saldo: Ativado para txid ${widget.txid}.");

    // Chama a função real que faz o trabalho pesado
    await _atualizarSaldoPrestador();

    // Libera o lock interno APÓS a conclusão (ou falha)
    // O finally dentro de _atualizarSaldoPrestador fará isso.
  }


  /// Garante que existe um registro na tabela 'pagamentos'. Retorna true se ok/existe, false se erro inesperado.
  Future<bool> _registrarPagamento() async {
    // ****** CONFIRA O NOME DA TABELA 'pagamentos' ******
    final String tabelaPagamentos = 'pagamentos';
    print("_registrarPagamento: Iniciando para txid ${widget.txid} na tabela '$tabelaPagamentos'");
    try {
      // 1. Verifica existência
      final existingPayment = await _supabase
          .from(tabelaPagamentos)
          .select('id_pagamento') // CONFIRA O NOME DA PK
          .eq('pix_transaction_id', widget.txid) // CONFIRA O NOME DA COLUNA TXID
          .limit(1)
          .maybeSingle();

      if (existingPayment != null) {
        print('_registrarPagamento: Pagamento (txid: ${widget.txid}) já existe. OK.');
        return true; // Já existe, sucesso.
      }

      // 2. Não existe, tenta inserir
      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) não encontrado. Tentando inserir...');
      final pagamentoData = {
        // ****** CONFIRA OS NOMES DAS COLUNAS ******
        'id_agendamento': widget.agendamentoId,
        'valor': widget.valorServico,
        'is_pix': true,
        'pix_transaction_id': widget.txid,
        'data_pagamento': DateTime.now().toIso8601String(),
        'status': 'confirmado', // Status do PIX em si
        'status_saldo': 'pendente' // Status do processamento do saldo
      };
      await _supabase.from(tabelaPagamentos).insert(pagamentoData);
      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) inserido com sucesso.');
      return true; // Inserido com sucesso

    } on PostgrestException catch (error) {
      // Trata especificamente erro de chave duplicada (concorrência)
      if (error.code == '23505') { // Código para unique_violation no PostgreSQL
        print('_registrarPagamento: Ignorando erro de chave duplicada (23505) para txid ${widget.txid}. Outra chamada inseriu. OK.');
        return true; // Considera sucesso, pois o registro existe.
      } else {
        // Outro erro do banco de dados
        print('_registrarPagamento: Erro DB inesperado para txid ${widget.txid}: code=${error.code}, message=${error.message}');
        if(mounted) setState(() => _mensagemErroProcessamento = 'Erro DB ao registrar pag.: ${error.message}');
        return false; // Falha
      }
    } catch (error) {
      // Erro genérico (rede, etc.)
      print('_registrarPagamento: Erro genérico para txid ${widget.txid}: $error');
      if(mounted) setState(() => _mensagemErroProcessamento = 'Erro geral ao registrar pag.: ${error.toString()}');
      return false; // Falha
    }
  }

  /// Atualiza o saldo do prestador e marca o pagamento como processado.
  /// Contém lógica para evitar duplicação e tratar erro PGRST116 sem mostrar na UI.
  Future<void> _atualizarSaldoPrestador() async {
    // Nomes de tabelas e colunas (ajuste conforme seu schema)
    final String tabelaPagamentos = 'pagamentos';
    final String tabelaUsuarios = 'usuarios';
    final String colIdPagamento = 'id_pagamento';
    final String colPixTxId = 'pix_transaction_id';
    final String colStatusSaldo = 'status_saldo';
    final String colIdUsuario = 'id_usuario';
    final String colSaldoUsuario = 'saldo';

    if (!mounted) {
      _isProcessingSaldo = false; // Libera lock se widget desmontado antes do finally
      print("_atualizarSaldoPrestador: Widget desmontado antes de iniciar. Abortando.");
      return;
    }
    // Indica que estamos começando o processo na UI
    setState(() {
      _atualizandoSaldo = true;
      _mensagemErroProcessamento = null; // Limpa erros anteriores de processamento de saldo
    });

    bool registroOk = false;
    try {
      print("_atualizarSaldoPrestador: Iniciando processamento para txid ${widget.txid}.");

      // 1. Garante o registro do pagamento (ou confirma existência)
      registroOk = await _registrarPagamento();
      if (!registroOk) {
        // Mensagem de erro já deve ter sido setada em _registrarPagamento
        print("_atualizarSaldoPrestador: Falha ao registrar/confirmar pagamento para txid ${widget.txid}. Abortando.");
        if (mounted) setState(() => _atualizandoSaldo = false);
        // O finally liberará o lock.
        return;
      }

      // --- INÍCIO DA SEÇÃO CRÍTICA (onde a lógica atômica é importante) ---
      print("_atualizarSaldoPrestador: Registro OK. Tentando marcar $colStatusSaldo como 'processado' para txid ${widget.txid}...");

      // 2. Tenta marcar atomicamente o 'status_saldo' como 'processado'
      final updateResponse = await _supabase
          .from(tabelaPagamentos)
          .update({colStatusSaldo: 'processado'})
          .eq(colPixTxId, widget.txid)
          .neq(colStatusSaldo, 'processado')
          .select(colIdPagamento)
          .maybeSingle();

      // 3. Verifica se a atualização do status_saldo ocorreu
      if (updateResponse == null) {
        // Já foi processado por outra chamada/instância ANTES desta.
        print("_atualizarSaldoPrestador: $colStatusSaldo já era 'processado' para txid ${widget.txid} (detectado na marcação). OK.");
        if (mounted) {
          setState(() {
            _saldoAtualizado = true; // Marca como sucesso, pois já foi feito.
            _atualizandoSaldo = false;
          });
        }
        // O finally liberará o lock.
        return;
      }

      // 4. Atualização do status_saldo OK. Busca o usuário.
      print("_atualizarSaldoPrestador: Marcação de $colStatusSaldo para 'processado' bem-sucedida (txid ${widget.txid}). Buscando usuário ${widget.prestadorId}...");

      // 5. Busca o usuário prestador
      final userResponse = await _supabase
          .from(tabelaUsuarios)
          .select(colSaldoUsuario)
          .eq(colIdUsuario, widget.prestadorId) // CONFIRA O NOME DA COLUNA ID
          .maybeSingle(); // Usa maybeSingle para retornar null em vez de erro se não achar

      // 6. Verifica se o usuário foi encontrado
      if (userResponse == null) {
        // ERRO GRAVE: O ID do prestador é válido mas não existe no banco.
        print("ERRO CRÍTICO em _atualizarSaldoPrestador: Prestador id ${widget.prestadorId} NÃO ENCONTRADO na tabela '$tabelaUsuarios' (txid: ${widget.txid}).");
        await _supabase
            .from(tabelaPagamentos)
            .update({colStatusSaldo: 'falha_usuario_nao_encontrado'})
            .eq(colPixTxId, widget.txid);
        if (mounted) {
          setState(() {
            _mensagemErroProcessamento = 'Erro Crítico: Prestador não encontrado no sistema.';
            _atualizandoSaldo = false;
            _saldoAtualizado = false;
          });
        }
        // O finally liberará o lock.
        return;
      }

      // 7. Usuário encontrado. Calcula e atualiza o saldo.
      print("_atualizarSaldoPrestador: Usuário ${widget.prestadorId} encontrado. Saldo atual: ${userResponse[colSaldoUsuario]}. Calculando e atualizando saldo...");
      double saldoAtual = (userResponse[colSaldoUsuario] as num?)?.toDouble() ?? 0.0;
      double novoSaldo = saldoAtual + widget.valorServico!; // valorServico validado no initState

      await _supabase
          .from(tabelaUsuarios)
          .update({colSaldoUsuario: novoSaldo})
          .eq(colIdUsuario, widget.prestadorId);

      // --- FIM DA SEÇÃO CRÍTICA ---
      print("_atualizarSaldoPrestador: Saldo do usuário (ID: ${widget.prestadorId}) atualizado para R\$ ${novoSaldo.toStringAsFixed(2)} (txid: ${widget.txid}). Processo concluído com sucesso.");

      // Atualiza a UI para refletir o sucesso final
      if (mounted) {
        setState(() {
          _saldoAtualizado = true;
          _atualizandoSaldo = false;
        });
      }

      // ########## INÍCIO DO BLOCO CATCH MODIFICADO (ignora PGRST116 na UI) ##########
    } catch (error) {
      print("_atualizarSaldoPrestador: ERRO INESPERADO durante processamento para txid ${widget.txid}: $error");

      bool showErrorInUI = true; // Flag para controlar exibição do erro na UI

      if (error is PostgrestException) {
        print("Detalhes Supabase: code=${error.code}, message=${error.message}, details=${error.details}");
        // Verifica se é o erro específico "PGRST116 / 0 rows" (código HTTP 406)
        if (error.code == 406 && (error.message.contains('PGRST116') || error.message.contains('0 rows'))) {
          print("Detectado erro PGRST116/406 (0 rows) - provavelmente de uma execução concorrente 'perdedora'. Será ignorado na UI.");
          showErrorInUI = false; // NÃO mostra este erro específico na UI
        }
      }

      // Atualiza o estado da UI com a mensagem de erro SOMENTE se não for o erro ignorado
      if (mounted && showErrorInUI) {
        setState(() {
          // Pega só a primeira linha do erro para UI mais limpa
          _mensagemErroProcessamento = 'Erro inesperado ao processar saldo: ${error.toString().split('\n').first}';
          _atualizandoSaldo = false; // Para o indicador de progresso
          _saldoAtualizado = false; // Garante que não mostre sucesso
        });
      } else if (mounted && !showErrorInUI) {
        // Loga que o erro foi ignorado, mas não atualiza a UI com erro.
        // A UI continuará mostrando "Processando..." até a instância "vencedora"
        // atualizar o estado para sucesso ou ocorrer um erro diferente.
        print("Erro PGRST116/406 ignorado para UI (txid: ${widget.txid}). Aguardando finalização da instância 'vencedora'.");
      }

      // Opcional: Marcar o status_saldo com um aviso ou erro para diagnóstico no DB
      try {
        final String statusRevert = showErrorInUI ? 'falha_processamento_inesperado' : 'aviso_concorrencia_pgrst116';
        await _supabase.from(tabelaPagamentos)
            .update({colStatusSaldo: statusRevert})
            .eq(colPixTxId, widget.txid);
        print("_atualizarSaldoPrestador: Status do pagamento (txid: ${widget.txid}) marcado como '$statusRevert' devido ao erro capturado.");
      } catch (revertError) {
        print("Erro adicional ao tentar reverter $colStatusSaldo para: $revertError");
      }
      // ########## FIM DO BLOCO CATCH MODIFICADO ##########

    } finally {
      // Garante que o lock INTERNO seja liberado SEMPRE.
      _isProcessingSaldo = false;
      print("Lock Saldo: Liberado para txid ${widget.txid}.");
    }
  } // Fim de _atualizarSaldoPrestador

  // Build da tela
  @override
  Widget build(BuildContext context) {
    // Determina a mensagem principal de erro a ser exibida na UI
    // Prioriza erro ocorrido durante o processamento do saldo (_mensagemErroProcessamento).
    // Se não houver erro de processamento, usa o erro vindo do status do PIX (widget.errorMessage).
    String? displayError = _mensagemErroProcessamento ?? widget.errorMessage;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do Pagamento'),
        automaticallyImplyLeading: false, // Remove botão voltar automático
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone baseado no SUCESSO DO PIX (widget.successful)
              Icon(
                widget.successful ? Icons.check_circle : Icons.error,
                color: widget.successful ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),

              // Título baseado no SUCESSO DO PIX
              Text(
                widget.successful
                    ? 'Pagamento PIX Confirmado!'
                    : 'Falha no Pagamento PIX',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.successful ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // --- Status do Processamento do Saldo ---
              // Mostra indicador de progresso SE o PIX foi sucesso E estamos processando o saldo
              if (widget.successful && _atualizandoSaldo)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processando atualização de saldo...'),
                  ],
                ),
              // Mostra sucesso do saldo SE o PIX foi sucesso E saldo foi atualizado E não estamos mais processando
              if (widget.successful && _saldoAtualizado && !_atualizandoSaldo)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0), // Espaçamento
                  child: Text(
                    'Saldo do prestador atualizado com sucesso!',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Mostra MENSAGEM DE ERRO (processamento ou PIX)
              // Apenas se houver um erro E não estivermos mostrando o loading do saldo
              if (displayError != null && !_atualizandoSaldo)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    displayError, // Mostra o erro determinado (processamento ou PIX)
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              // --- Fim Status do Processamento do Saldo ---

              const SizedBox(height: 8),

              // Informações da transação (sempre mostrar txid)
              Text(
                'ID da transação PIX: ${widget.txid}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              // Mostra valor apenas se o PIX foi sucesso (e valor não for nulo)
              if (widget.successful && widget.valorServico != null)
                Text(
                  'Valor: R\$ ${widget.valorServico!.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 32),

              // Botão para voltar para a tela inicial
              ElevatedButton(
                onPressed: () {
                  // Navega de volta removendo todas as telas até a primeira
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Voltar para o Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}