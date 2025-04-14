import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servblu/widgets/input_dropdown_field.dart';
import 'package:servblu/widgets/input_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/services/servico_service.dart';

import '../../widgets/build_header.dart';

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
    // If loading, show progress indicator
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

    return GestureDetector(
      // Add this to dismiss keyboard when tapping outside
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            BuildHeader(title: 'Anunciar Serviço', backPage: false, refresh: false,),
            // Wrap the scrollable content in an Expanded widget
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(), // Ensure scrolling
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 20),

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
                              size: 40,
                              color: Color(0xFF017DFE),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicionar foto',
                              style: TextStyle(
                                  color: Color(0xFF017DFE),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold
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
                    Text('Qual serviço você quer anunciar?',style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),),
                    SizedBox(height: 16,),
                    // Input Fields
                    InputField(
                      icon: Icons.work_outline,
                      hintText: 'Nome do Serviço',
                      obscureText: false,
                      controller: _nomeController,
                    ),

                    SizedBox(height: 5),

                    InputField(
                      hintText: 'Descrição',
                      obscureText: false,
                      controller: _descricaoController,
                      isDescription: true,
                    ),

                    SizedBox(height: 5),

                    InputField(
                      icon: Icons.attach_money,
                      hintText: 'Preço (R\$)',
                      obscureText: false,
                      controller: _precoController,
                    ),

                    SizedBox(height: 5),

                    // Category Dropdown
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF017DFE),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.category_outlined, color: Color(0xFF017DFE)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                value: _categoriaSelecionada,
                                decoration: const InputDecoration(
                                  hintText: 'Categoria',
                                  border: InputBorder.none,
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
                          ),
                        ],
                      ),
                    ),

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
                        'Anunciar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Add extra space at the bottom to ensure the last element is fully visible
                    SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
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