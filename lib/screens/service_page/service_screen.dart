import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/models/servicos/servico_service.dart';
import 'dart:io';

class ServicoTestScreen extends StatefulWidget {
  @override
  _ServicoTestScreenState createState() => _ServicoTestScreenState();
}

class _ServicoTestScreenState extends State<ServicoTestScreen> {
  final ServicoService _servicoService = ServicoService();
  final List<String> categorias = [
    'Escritório',
    'Eletricista',
    'Tecnologia',
    'Manutenção',
    'Higienização',
  ];
  String? _categoriaSelecionada;
  File? _imagemSelecionada;
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _precoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _escolherImagem() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800, // Redimensiona a imagem para reduzir o tamanho
        imageQuality: 85, // Comprime a imagem para reduzir o tamanho
      );

      if (pickedFile != null) {
        setState(() {
          _imagemSelecionada = File(pickedFile.path);
        });

        // Exibir tamanho da imagem para debug
        final fileSize = await _imagemSelecionada!.length();
        print('Tamanho da imagem selecionada: ${(fileSize / 1024).toStringAsFixed(2)} KB');
      }
    } catch (e) {
      _mostrarMensagemErro('Erro ao selecionar imagem: $e');
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

  // Validação dos campos antes de cadastrar
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
          return; // Make sure to return here to stop the process
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Anunciar Serviço'),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processando, por favor aguarde...'),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: 'Nome do serviço',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(
                labelText: 'Descrição',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _categoriaSelecionada,
              decoration: InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
              hint: Text('Selecione uma categoria'),
              onChanged: (String? novaCategoria) {
                setState(() {
                  _categoriaSelecionada = novaCategoria;
                });
              },
              items: categorias.map<DropdownMenuItem<String>>((String categoria) {
                return DropdownMenuItem<String>(
                  value: categoria,
                  child: Text(categoria),
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            Text('Imagem do Serviço:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),

            // Área para exibir e selecionar imagem
            Container(
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: _imagemSelecionada != null
                    ? Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.file(
                      _imagemSelecionada!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 150,
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _imagemSelecionada = null;
                        });
                      },
                    ),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 50, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Nenhuma imagem selecionada'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _escolherImagem,
              icon: Icon(Icons.photo_library),
              label: Text('Selecionar Imagem'),
            ),
            SizedBox(height: 16),

            TextFormField(
              controller: _precoController,
              decoration: InputDecoration(
                labelText: 'Preço (em reais)',
                border: OutlineInputBorder(),
                prefix: Text('R\$ '),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 24),

            ElevatedButton(
              onPressed: _cadastrarServico,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'CADASTRAR SERVIÇO',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}