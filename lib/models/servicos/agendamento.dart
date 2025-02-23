/*
criarAgendamento(Agendamento agendamento)
Descrição: Registra um novo agendamento, marcando-o inicialmente como "pendente"
e vinculando o contratante, prestador, serviço e horário selecionado.

listarAgendamentosPorCliente(int idCliente)
Descrição: Retorna os agendamentos realizados por um contratante.

listarAgendamentosPorPrestador(int idPrestador)
Descrição: Retorna os agendamentos recebidos por um prestador.

atualizarStatusAgendamento(int idAgendamento, String novoStatus)
Descrição: Permite atualizar o status do agendamento (ex.: de "pendente" para
"confirmado", "concluído" ou "cancelado").

verificarDisponibilidade(int idPrestador, DateTime data, int horario)
Descrição: Valida se o horário escolhido está livre para agendamento, evitando conflitos.
*/