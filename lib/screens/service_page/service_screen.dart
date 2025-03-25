import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/models/servicos/servico_service.dart';

class ServicoTestScreen extends StatefulWidget {
  @override
  _ServiceScreenState createState() => _ServiceScreenState();
}

class _ServiceScreenState extends State<ServicoTestScreen> {
  final ServicoService _servicoService = ServicoService();
  final List<String> categorias = [
    'Escritório',
    'Eletricista',
    'Tecnologia',
    'Manutenção',
    'Higienização',
  ];

  File? _imagemSelecionada;
  String? _categoriaSelecionada;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _escolherImagem() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagemSelecionada = File(pickedFile.path);
        });
      }
    } catch (e) {
      _mostrarMensagemErro('Erro ao selecionar imagem: $e');
    }
  }

  // Método para validar os campos
  bool _validarCampos() {
    if (_nomeController.text.isEmpty) {
      _mostrarMensagemErro('O nome do serviço é obrigatório');
      return false;
    }

    if (_descricaoController.text.isEmpty) {
      _mostrarMensagemErro('A descrição é obrigatória');
      return false;
    }

    if (_categoriaSelecionada == null) {
      _mostrarMensagemErro('Selecione uma categoria');
      return false;
    }

    if (_precoController.text.isEmpty) {
      _mostrarMensagemErro('O preço é obrigatório');
      return false;
    }

    try {
      double preco = double.parse(_precoController.text);
      if (preco <= 0) {
        _mostrarMensagemErro('O preço deve ser maior que zero');
        return false;
      }
    } catch (e) {
      _mostrarMensagemErro('Preço inválido');
      return false;
    }

    return true;
  }

  // Método para cadastrar o serviço
  Future<void> _cadastrarServico() async {
    // Validar os campos primeiro
    if (!_validarCampos()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não está logado');
      }

      String? imageUrl;
      if (_imagemSelecionada != null) {
        try {
          // Verificar se o arquivo existe
          if (!_imagemSelecionada!.existsSync()) {
            throw Exception('Arquivo de imagem não existe: ${_imagemSelecionada!.path}');
          }

          print('Iniciando upload da imagem...');
          imageUrl = await _servicoService.uploadImagem(_imagemSelecionada!);
          print('Upload concluído com sucesso: $imageUrl');

          // Add this verification
          if (imageUrl == null) {
            throw Exception('Upload da imagem falhou: URL retornou nula');
          }
        } catch (e) {
          print('Erro no upload da imagem: $e');
          _mostrarMensagemErro('Erro no upload da imagem: $e');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      double preco = double.parse(_precoController.text);

      final servico = Servico(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        categoria: _categoriaSelecionada!,
        imgServico: imageUrl,
        preco: preco,
        idPrestador: user.id,
      );

      print('Cadastrando serviço no banco de dados...');
      await _servicoService.cadastrarServico(servico);
      print('Serviço cadastrado com sucesso!');

      _mostrarMensagemSucesso('Serviço cadastrado com sucesso!');

      // Limpar os campos após o cadastro bem-sucedido
      _limparCampos();
    } catch (e) {
      print('ERRO DETALHADO ao cadastrar serviço: $e');
      _mostrarMensagemErro('Erro ao cadastrar serviço: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para limpar todos os campos
  void _limparCampos() {
    setState(() {
      _nomeController.clear();
      _descricaoController.clear();
      _precoController.clear();
      _categoriaSelecionada = null;
      _imagemSelecionada = null;
    });
  }

  // Métodos para mostrar mensagens de sucesso e erro
  void _mostrarMensagemSucesso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.green),
    );
  }

  void _mostrarMensagemErro(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Se estiver carregando, mostrar indicador de progresso
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processando, por favor aguarde...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    'Anunciar Serviço',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Image selection
                GestureDetector(
                  onTap: _escolherImagem,
                  child: Container(
                    height: 180,
                    decoration: BoxDecoration(
                      color: Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: _imagemSelecionada == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 50,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Adicionar foto',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _imagemSelecionada!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Input Fields
                _buildInputField(
                  controller: _nomeController,
                  labelText: 'Nome do Serviço',
                  icon: Icons.work_outline,
                ),

                SizedBox(height: 16),

                _buildInputField(
                  controller: _descricaoController,
                  labelText: 'Descrição',
                  icon: Icons.description_outlined,
                  maxLines: 3,
                ),

                SizedBox(height: 16),

                _buildInputField(
                  controller: _precoController,
                  labelText: 'Preço (R\$)',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),

                SizedBox(height: 16),

                // Category Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _categoriaSelecionada,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.category_outlined, color: Colors.grey),
                      hintText: 'Categoria',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    dropdownColor: Colors.white,
                    items: categorias.map((String categoria) {
                      return DropdownMenuItem<String>(
                        value: categoria,
                        child: Text(categoria),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _categoriaSelecionada = newValue;
                      });
                    },
                  ),
                ),

                SizedBox(height: 24),

                // Continue Button
                ElevatedButton(
                  onPressed: _cadastrarServico,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF2196F3),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to build consistent input fields
  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          hintText: labelText,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }
}