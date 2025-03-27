import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/models/servicos/servico_service.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:servblu/widgets/input_field.dart';

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
    _descricaoController =
        TextEditingController(text: widget.servico.descricao);
    _precoController =
        TextEditingController(text: widget.servico.preco?.toString() ?? '');
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
        SnackBar(
            content: Text('Erro ao selecionar imagem: $e'),
            backgroundColor: Colors.red),
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

    print('--- INICIANDO ATUALIZAÇÃO DO SERVIÇO ---');
    print('Estado inicial:');
    print('- ID do serviço: ${widget.servico.idServico}');
    print('- URL da imagem atual do serviço: ${widget.servico.imgServico}');
    print('- _imagemUrl (estado atual): $_imagemUrl');
    print('- Nova imagem selecionada: ${_novaImagem != null ? 'SIM' : 'NÃO'}');
    if (_novaImagem != null) {
      print('- Caminho da nova imagem: ${_novaImagem!.path}');
      print('- Tamanho da nova imagem: ${await _novaImagem!.length()} bytes');
    }

    setState(() {}); // Atualizar a UI para indicar o processo

    try {
      String? newImageUrl = _imagemUrl;

      // Se o usuário escolheu uma nova imagem
      if (_novaImagem != null) {
        print('Fazendo upload da nova imagem...');
        newImageUrl = await _servicoService.uploadImagem(_novaImagem!);
        print(
            'Resultado do upload: ${newImageUrl != null ? 'SUCESSO' : 'FALHA'}');
        print('Nova URL da imagem: $newImageUrl');

        if (newImageUrl == null) {
          throw Exception('Falha ao fazer upload da imagem');
        }
      }
      // Se o usuário removeu a imagem existente (sem escolher uma nova)
      else if (_imagemUrl == null && widget.servico.imgServico != null) {
        print('Imagem removida pelo usuário (sem nova imagem)');
        newImageUrl = null;
      }

      print('Criando objeto de serviço atualizado:');
      print('- Nome: ${_nomeController.text}');
      print('- Descrição: ${_descricaoController.text}');
      print('- Preço: ${_precoController.text}');
      print('- Categoria: $_categoriaSelecionada');
      print('- URL da imagem final: $newImageUrl');

      final updatedServico = widget.servico.copyWith(
        nome: _nomeController.text,
        descricao: _descricaoController.text,
        preco: double.tryParse(_precoController.text) ?? 0.0,
        categoria: _categoriaSelecionada!,
        imgServico: newImageUrl, // Pode ser null para remover a imagem
      );

      print('Objeto de serviço criado:');
      print('- ID: ${updatedServico.idServico}');
      print('- URL da imagem no objeto: ${updatedServico.imgServico}');
      print('- JSON completo: ${updatedServico.toJson()}');

      print('Chamando método editarServico()...');
      await _servicoService.editarServico(updatedServico);
      print('Método editarServico() concluído com sucesso');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Serviço atualizado com sucesso!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
        Navigator.pop(context, 'updated');
      }
    } catch (e) {
      print('ERRO AO ATUALIZAR SERVIÇO: $e');
      print('--- ATUALIZAÇÃO FALHOU ---');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao atualizar serviço: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            BuildHeader(
              title: 'Editar Serviço',
              backPage: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Widget de foto adaptado com remoção sobreposta
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: _escolherImagem,
                            child: Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Color(0xFFF0F0F0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: _novaImagem == null
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
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    )
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        _novaImagem!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                            ),
                          ),
                          // Botão de remoção estilizado e posicionado no canto superior direito
                          if (_novaImagem != null || _imagemUrl != null)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: InkWell(
                                onTap: _removerImagem,
                                borderRadius: BorderRadius.circular(30),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white70,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: EdgeInsets.all(8),
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 16),
                      InputField(
                        icon: Icons.work_outline,
                        hintText: 'Nome do Serviço',
                        obscureText: false,
                        controller: _nomeController,
                      ),
                      SizedBox(height: 16),
                      InputField(
                        icon: Icons.description_outlined,
                        hintText: 'Descrição',
                        obscureText: false,
                        controller: _descricaoController,
                      ),
                      SizedBox(height: 16),
                      InputField(
                        icon: Icons.attach_money,
                        hintText: 'Preço (R\$)',
                        obscureText: false,
                        controller: _precoController,
                      ),
                      SizedBox(height: 16),
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
                            const Icon(Icons.category_outlined,
                                color: Color(0xFF017DFE)),
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
                      SizedBox(height: 70),
                      Container(
                        width: 400,
                        child: ElevatedButton(
                          onPressed: _updateService,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF2196F3),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Atualizar Serviço',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
