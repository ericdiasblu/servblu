import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/models/servicos/servico_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/screens/service_page/edit_servico_screen.dart';

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
  bool isOwner = false;
  bool isLoading = false;
  Map<String, dynamic>? userDetails;

  @override
  void initState() {
    super.initState();
    _checkOwnership();
    _logImageUrl(); // Adiciona log da URL da imagem para depuração
    _fetchUserDetails();
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
      final details = await _servicoService.getUserDetails(widget.servico.idPrestador!);
      setState(() {
        userDetails = details;
      });
    } catch (e) {
      print('Erro ao carregar detalhes do usuário: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível carregar informações do prestador')),
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
      MaterialPageRoute(builder: (context) => EditServicoScreen(servico: widget.servico)),
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
        content: Text("Tem certeza que deseja excluir este serviço? Esta ação não pode ser desfeita."),
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

  Widget _buildUserInfoSection() {
    if (userDetails == null) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Informações do Prestador",
            style: Theme.of(context).textTheme.headlineSmall,
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
                    SizedBox(height: 8),
                    // Endereço
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userDetails?['endereco'] ?? 'Endereço não disponível',
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.servico.nome),
        actions: isOwner
            ? [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _navigateToEditPage,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog();
            },
          ),
        ]
            : null,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagem do serviço - Bloco melhorado
            if (widget.servico.imgServico != null &&
                widget.servico.imgServico!.isNotEmpty)
              Container(
                height: 200,
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
                            Icon(Icons.error_outline, size: 40, color: Colors.red),
                            SizedBox(height: 8),
                            Text('Não foi possível carregar a imagem',
                                style: TextStyle(color: Colors.red[700])),
                            SizedBox(height: 4),
                            Text(widget.servico.imgServico ?? 'URL inválida',
                                style: TextStyle(fontSize: 10, color: Colors.grey[700])),
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
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
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
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.servico.nome,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      Chip(
                        label: Text(widget.servico.categoria),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  Text(
                    "Descrição:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.servico.descricao,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 24),

                  if (widget.servico.preco != null)
                    Row(
                      children: [
                        Text(
                          "Preço:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "R\$ ${widget.servico.preco!.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 32),

                  // Botão para contratar/entrar em contato (para não-proprietários)
                  if (!isOwner)
                    Center(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.contact_phone),
                        label: Text("Entrar em Contato"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        onPressed: () {
                          // Implementar a lógica para entrar em contato
                          // Exemplo: abrir tela de chat ou mostrar informações de contato
                        },
                      ),
                    ),
                ],
              ),
            ),
            _buildUserInfoSection(),
          ],
        ),
      ),
    );
  }
}