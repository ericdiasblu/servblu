import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/services/servico_service.dart';
import 'package:servblu/services/avaliacao_service.dart';
import 'package:servblu/models/avaliacoes/avaliacao.dart';
import 'package:servblu/screens/home_page/search_screen.dart';
import 'package:servblu/widgets/build_circle_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/screens/service_page/edit_servico_screen.dart';
import 'package:intl/intl.dart';

import '../../widgets/tool_loading.dart';
import '../schedule_page/agendamento_screen.dart';

class ServiceDetailsPage extends StatefulWidget {
  final Servico servico;

  const ServiceDetailsPage({
    Key? key,
    required this.servico,
  }) : super(key: key);

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  final ServicoService _servicoService = ServicoService();
  final AvaliacaoService _avaliacaoService = AvaliacaoService();
  bool isOwner = false;
  bool isLoading = false;
  Map<String, dynamic>? userDetails;
  List<Avaliacao> avaliacoes = [];
  double mediaAvaliacoes = 0.0;
  int totalAvaliacoes = 0;
  final PageController _pageController = PageController();
  double mediaAvaliacoesUsuario = 0.0;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _logImageUrl(); // Adiciona log da URL da imagem para depuração
    _fetchUserDetails();
    _carregarAvaliacoes();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // No método _carregarAvaliacoes() da ServiceDetailsPage:
  Future<void> _carregarAvaliacoes() async {
    try {
      if (widget.servico.idServico != null) {
        // Carregar apenas avaliações deste serviço específico
        final listaAvaliacoes = await _avaliacaoService
            .listarAvaliacoesPorServico(widget.servico.idServico!);

        // Usar a média já calculada no objeto servico, se disponível
        double media;
        if (widget.servico.avaliacaoMedia != null) {
          media = widget.servico.avaliacaoMedia!;
        } else {
          // Caso não esteja disponível, calcular a média
          media = await _avaliacaoService
              .calcularMediaAvaliacoesServico(widget.servico.idServico!);
        }

        final avaliacaoUsuario = await _avaliacaoService .calcularMediaAvaliacoesPrestador(widget.servico.idPrestador);

        // Contar total de avaliações
        final total = await _avaliacaoService
            .contarAvaliacoesServico(widget.servico.idServico!);

        setState(() {
          avaliacoes = listaAvaliacoes;
          mediaAvaliacoes = media;
          totalAvaliacoes = total;
          //AVALIAÇÃO DO USUÁRIO
          mediaAvaliacoesUsuario = avaliacaoUsuario;
        });
      }
    } catch (e) {
      print('Erro ao carregar avaliações: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar avaliações')),
        );
      }
    }
  }

  void _logImageUrl() {
    print('URL da imagem do serviço: ${widget.servico.imgServico}');
  }

  void _checkOwnership() {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      setState(() {
        isOwner = currentUser.id == widget.servico.idPrestador;
      });
    }
  }

  Future<void> _fetchUserDetails() async {
    try {
      final details =
      await _servicoService.getUserDetails(widget.servico.idPrestador!);
      setState(() {
        userDetails = details;
      });
    } catch (e) {
      print('Erro ao carregar detalhes do usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Não foi possível carregar informações do prestador')),
        );
      }
    }
  }

  Future<void> _deleteService() async {
    setState(() {
      isLoading = true;
    });

    try {
      await _servicoService.removerServico(widget.servico.idServico!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Serviço removido com sucesso')),
        );
        Navigator.pop(context, 'deleted');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover serviço: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _navigateToEditPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditServicoScreen(servico: widget.servico)),
    );

    if (result == true) {
      setState(() {
        // Atualizar a tela com os novos dados do serviço
      });
    }
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Excluir Serviço"),
        content: Text(
            "Tem certeza que deseja excluir este serviço? Esta ação não pode ser desfeita."),
        actions: [
          TextButton(
            child: Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text("Excluir"),
            onPressed: () {
              Navigator.pop(context);
              _deleteService();
            },
          ),
        ],
      ),
    );
  }

  void navigateToSearch() {
    Navigator.pop(context);
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Color(0xFFFCD40E), size: 18);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Color(0xFFFCD40E), size: 18);
        } else {
          return Icon(Icons.star_border, color: Color(0xFFFCD40E), size: 18);
        }
      }),
    );
  }

  Widget _buildUserInfoSection() {
    if (userDetails == null) {
      return Center(child: ToolLoadingIndicator(color: Colors.blue, size: 45));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Informações do Prestador",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40,
              backgroundImage: userDetails?['foto_perfil'] != null
                  ? NetworkImage(userDetails!['foto_perfil'])
                  : null,
              child: userDetails?['foto_perfil'] == null
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nome
                  Text(
                    userDetails?['nome'] ?? 'Nome não disponível',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  // Telefone
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        userDetails?['telefone'] ?? 'Telefone não disponível',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Text(
                    //AVALIAÇÃO DO USUÁRIO
                    '${mediaAvaliacoesUsuario.toStringAsFixed(1)} (${totalAvaliacoes} ${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'})',
                    style: TextStyle(
                        fontWeight: FontWeight.w400, fontSize: 12),
                  ),
                  // Endereço
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvaliacoesSection() {
    if (avaliacoes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text(
            'Este serviço ainda não possui avaliações',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Avaliações dos Clientes',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
        Container(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: avaliacoes.length,
            itemBuilder: (context, index) {
              final avaliacao = avaliacoes[index];
              return _buildAvaliacaoCard(avaliacao);
            },
          ),
        ),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              avaliacoes.length,
                  (index) => Container(
                width: 8,
                height: 8,
                margin: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pageController.hasClients &&
                      _pageController.page?.round() == index
                      ? Colors.blue
                      : Colors.grey[300],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvaliacaoCard(Avaliacao avaliacao) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: avaliacao.fotoPerfilCliente != null
                      ? NetworkImage(avaliacao.fotoPerfilCliente!)
                      : null,
                  child: avaliacao.fotoPerfilCliente == null
                      ? Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avaliacao.nomeCliente ?? 'Cliente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStarRating(avaliacao.nota),
                          SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy').format(avaliacao.dataAvaliacao),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (avaliacao.comentario.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                avaliacao.comentario,
                style: TextStyle(
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: isOwner
          ? null
          : Container(
        color: Colors.white,
        height: 100,
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Center(
            child: Container(
              width: double.infinity,
              child: ElevatedButton(
                child: Text(
                  "Agendar Serviço",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF2196F3),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AgendamentoScreen(
                        idServico: widget.servico.idServico!,
                        idPrestador: widget.servico.idPrestador!,
                      ),
                    ),
                  );

                  if (result == true) {
                    // O agendamento foi concluído com sucesso
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Agendamento realizado com sucesso!')),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? Center(child: ToolLoadingIndicator(color: Colors.blue, size: 45))
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do serviço - Bloco melhorado
            if (widget.servico.imgServico != null &&
                widget.servico.imgServico!.isNotEmpty)
              Stack(
                children: [
                  Container(
                    height: 350,
                    width: double.infinity,
                    child: Image.network(
                      widget.servico.imgServico!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        print('Erro ao carregar imagem: $error');
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 40, color: Colors.red),
                                SizedBox(height: 8),
                                Text('Não foi possível carregar a imagem',
                                    style: TextStyle(
                                        color: Colors.red[700])),
                                SizedBox(height: 4),
                                Text(
                                    widget.servico.imgServico ??
                                        'URL inválida',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700])),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes !=
                                  null
                                  ? loadingProgress
                                  .cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                          const EdgeInsets.only(top: 40, left: 20),
                          child: BuildCircleButton(
                              icon: Icons.arrow_back,
                              funcaoBotao: navigateToSearch),
                        ),
                        if (isOwner)
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 8.0, right: 20),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 30,
                                ),
                                BuildCircleButton(
                                  icon: Icons.share,
                                  funcaoBotao: () {},
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                BuildCircleButton(
                                  icon: Icons.delete,
                                  funcaoBotao:
                                  _showDeleteConfirmationDialog,
                                ),
                                SizedBox(
                                  height: 8,
                                ),
                                BuildCircleButton(
                                    icon: Icons.edit,
                                    funcaoBotao: _navigateToEditPage),
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                  Positioned(
                    top: 330,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 30,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(45),
                          topRight: Radius.circular(45),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                width: double.infinity,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 8),
                      Text('Sem imagem disponível',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(
                  top: 16, left: 25, right: 25, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color(0xFF479696).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Text(
                        '${widget.servico.categoria}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF479696),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Text(
                        "R\$ ${widget.servico.preco?.toStringAsFixed(2)}",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 30),
                          child: Text(
                            widget.servico.nome,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 25, top: 10),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Color(0xFFFCD40E),
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          //AVALIAÇÂO EM CIMA
                          '${mediaAvaliacoes.toStringAsFixed(1)} (${totalAvaliacoes} ${totalAvaliacoes == 1 ? 'avaliação' : 'avaliações'})',
                          style: TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Text(
                      userDetails?['endereco'] ??
                          'Endereço não disponível',
                      style: TextStyle(
                          fontWeight: FontWeight.w400, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Stack(
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.only(left: 16, bottom: 16),
                        child: DefaultTabController(
                          length: 2,
                          child: Column(
                            children: <Widget>[
                              TabBar(
                                isScrollable: true,
                                labelColor: Colors.blueAccent,
                                indicatorColor: Colors.blueAccent,
                                indicator: UnderlineTabIndicator(
                                  borderSide: BorderSide(
                                      width: 3, color: Colors.blue),
                                  insets: EdgeInsets.symmetric(
                                      horizontal: 120),
                                ),
                                tabs: <Widget>[
                                  Tab(text: "         Sobre         "),
                                  Tab(
                                      text:
                                      "         Avaliações         "),
                                ],
                              ),
                              SizedBox(
                                height:
                                MediaQuery.of(context).size.height -
                                    (isOwner ? 500 : 550),
                                child: TabBarView(
                                  children: <Widget>[
                                    SingleChildScrollView(
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 16),
                                            Text(
                                              'Sobre o Serviço',
                                              style: TextStyle(
                                                  fontWeight:
                                                  FontWeight.w700),
                                            ),
                                            SizedBox(height: 16),
                                            Text(
                                              widget.servico.descricao,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                            SizedBox(height: 16),
                                            _buildUserInfoSection(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SingleChildScrollView(
                                      child: _buildAvaliacoesSection(),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: isOwner ? 0 : 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}