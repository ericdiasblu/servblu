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

  Future<void> _escolherImagem() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagemSelecionada = File(pickedFile.path);
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

  Future<void> _cadastrarServico() async {
    try {
      final SupabaseClient supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não está logado');
      }

      final servico = Servico(
        // Não é mais necessário passar o idServico, será gerado pelo service
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        categoria: _categoriaSelecionada!,
        imgServico: _imagemSelecionada != null ? _imagemSelecionada!.path : null,
        preco: double.parse(_precoController.text),
        idPrestador: user.id, // UUID do usuário logado
      );

      await _servicoService.cadastrarServico(servico);
      _mostrarMensagemSucesso('Serviço cadastrado com sucesso!');

      // Limpar os campos após o cadastro bem-sucedido
      _limparCampos();
    } catch (e) {
      _mostrarMensagemErro('Erro ao cadastrar serviço: $e');
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            DropdownButton<String>(
              value: _categoriaSelecionada,
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
            _imagemSelecionada != null
                ? Image.file(_imagemSelecionada!, height: 100, width: 100)
                : Text('Nenhuma imagem selecionada'),
            ElevatedButton(
              onPressed: _escolherImagem,
              child: Text('Escolher Imagem'),
            ),
            TextFormField(
                controller: _precoController,
                decoration: InputDecoration(labelText: 'Preço'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O preço é obrigatório';
                  }
                  final preco = double.tryParse(value);
                  if (preco == null || preco <= 0) {
                    return 'O preço deve ser maior que 0';
                  }
                  return null;
                }
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _cadastrarServico,
              child: Text('Cadastrar Serviço'),
            ),
          ],
        ),
      ),
    );
  }
}