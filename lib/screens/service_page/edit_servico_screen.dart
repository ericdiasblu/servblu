import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/models/servicos/servico_service.dart';

class EditServicoScreen extends StatefulWidget {
  final Servico servico;

  const EditServicoScreen({Key? key, required this.servico}) : super(key: key);

  @override
  _EditServicoScreenState createState() => _EditServicoScreenState();
}

class _EditServicoScreenState extends State<EditServicoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServicoService _servicoService = ServicoService();

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  String? _categoriaSelecionada;
  File? _novaImagem;
  String? _imagemUrl;

  final List<String> categorias = [
    'Escritório',
    'Eletricista',
    'Tecnologia',
    'Manutenção',
    'Higienização',
  ];

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.servico.nome);
    _descricaoController = TextEditingController(text: widget.servico.descricao);
    _precoController = TextEditingController(text: widget.servico.preco?.toString() ?? '');
    _categoriaSelecionada = widget.servico.categoria;
    _imagemUrl = widget.servico.imgServico; // Carregar a imagem existente
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    super.dispose();
  }

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
          _novaImagem = File(pickedFile.path);
          _imagemUrl = null; // Esconder a URL antiga
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _removerImagem() async {
    setState(() {
      _novaImagem = null;
      _imagemUrl = null;
    });
  }

  Future<void> _updateService() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {}); // Atualizar a UI para indicar o processo

    try {
      String? newImageUrl = _imagemUrl;

      // Se o usuário escolheu uma nova imagem, fazer o upload para o Supabase
      if (_novaImagem != null) {
        newImageUrl = await _servicoService.uploadImagem(_novaImagem!);
      }

      final updatedServico = widget.servico.copyWith(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        preco: double.tryParse(_precoController.text) ?? 0.0,
        categoria: _categoriaSelecionada!,
        imgServico: newImageUrl, // Atualizar com a nova imagem ou manter a antiga
      );

      await _servicoService.editarServico(updatedServico);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Serviço atualizado com sucesso!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao atualizar serviço: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Editar Serviço')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nomeController,
                  decoration: InputDecoration(labelText: 'Nome'),
                  validator: (value) => value!.isEmpty ? 'Informe um nome' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _descricaoController,
                  decoration: InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  validator: (value) => value!.isEmpty ? 'Informe uma descrição' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _precoController,
                  decoration: InputDecoration(labelText: 'Preço'),
                  keyboardType: TextInputType.number,
                  validator: (value) => value!.isEmpty ? 'Informe um preço' : null,
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
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: _novaImagem != null
                        ? Image.file(_novaImagem!, fit: BoxFit.cover, width: double.infinity, height: 150)
                        : _imagemUrl != null
                        ? Image.network(_imagemUrl!, fit: BoxFit.cover, width: double.infinity, height: 150)
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _escolherImagem,
                      icon: Icon(Icons.photo_library),
                      label: Text('Selecionar Imagem'),
                    ),
                    SizedBox(width: 16),
                    if (_novaImagem != null || _imagemUrl != null)
                      ElevatedButton.icon(
                        onPressed: _removerImagem,
                        icon: Icon(Icons.delete, color: Colors.red),
                        label: Text('Remover'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _updateService,
                  style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16)),
                  child: Text('SALVAR ALTERAÇÕES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
