import 'package:flutter/material.dart';

class BuildDropdownField extends StatefulWidget {
  final IconData icon; // Adicionando o ícone
  final String hintText;
  final String? selectedOption;
  final ValueChanged<String?>? onChanged;
  final TextEditingController controller; // Controlador obrigatório

  const BuildDropdownField({
    Key? key,
    required this.icon, // Ícone obrigatório
    required this.hintText,
    required this.controller, // Controlador obrigatório
    this.selectedOption,
    this.onChanged,
  }) : super(key: key);

  @override
  _BuildDropdownFieldState createState() => _BuildDropdownFieldState();
}

class _BuildDropdownFieldState extends State<BuildDropdownField> {
  final List<String> _options = [
    // Bairros de Blumenau
    'Badenfurt',
    'Fidélis',
    'Itoupava Central',
    'Itoupavazinha',
    'Salto do Norte',
    'Testo Salto',
    'Vila Itoupava',
    'Fortaleza',
    'Fortaleza Alta',
    'Itoupava Norte',
    'Nova Esperança',
    'Ponta Aguda',
    'Tribess',
    'Vorstadt',
    'Da Glória',
    'Garcia',
    'Progresso',
    'Ribeirão Fresco',
    'Valparaíso',
    'Vila Formosa',
    'Água Verde',
    'Do Salto',
    'Escola Agrícola',
    'Passo Manso',
    'Salto Weissbach',
    'Velha',
    'Velha Central',
    'Velha Grande',
    'Boa Vista',
    'Bom Retiro',
    'Centro',
    'Itoupava Seca',
    'Jardim Blumenau',
    'Victor Konder',
    'Vila Nova',
  ];

  String? _currentSelectedOption; // Variável para armazenar a opção selecionada

  @override
  void initState() {
    super.initState();
    // Inicializa a opção selecionada com a opção recebida
    _currentSelectedOption = widget.selectedOption;
    if (_currentSelectedOption != null) {
      widget.controller.text = _currentSelectedOption!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Icon(widget.icon, color: const Color(0xFF017DFE)), // Ícone à esquerda
          const SizedBox(width: 10), // Espaçamento entre o ícone e o dropdown
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                hint: Text(
                  widget.hintText,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 15,
                  ),
                ),
                value: _currentSelectedOption, // Usar a variável local para mostrar a seleção
                onChanged: (String? newValue) {
                  setState(() {
                    _currentSelectedOption = newValue; // Atualiza a opção selecionada
                    widget.onChanged?.call(newValue);
                    // Atualiza o controlador com a nova opção selecionada
                    widget.controller.text = newValue ?? '';
                  });
                },
                items: _options.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                isExpanded: true, // Expande o dropdown para ocupar todo o espaço
              ),
            ),
          ),
        ],
      ),
    );
  }
}
