import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../core/services/storage_service.dart';
import '../models/produto.dart';

class ProdutoEditScreen extends StatefulWidget {
  final Produto produto;
  final bool isVistoriaReview;
  final List<String> camposAlteradosPelaIA;

  const ProdutoEditScreen({
    super.key,
    required this.produto,
    this.isVistoriaReview = false,
    this.camposAlteradosPelaIA = const []
  });

  @override
  State<ProdutoEditScreen> createState() => _ProdutoEditScreenState();
}

class _ProdutoEditScreenState extends State<ProdutoEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final StorageService _storage = Modular.get<StorageService>();

  late TextEditingController _nomeController;
  late TextEditingController _categoriaController;
  late TextEditingController _valorEstimadoController;
  late TextEditingController _quantidadeController;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.produto.nome);
    _categoriaController = TextEditingController(text: widget.produto.categoria);
    _valorEstimadoController = TextEditingController(text: widget.produto.valorEstimado);
    _quantidadeController = TextEditingController(text: widget.produto.quantidade.toString());
  }

  Future<void> _salvar() async {
    if (widget.produto.isDanificado) {
      await _storage.saveProduto(widget.produto);
      Modular.to.pop();
      return;
    }

    if (_formKey.currentState!.validate()) {
      widget.produto.nome = _nomeController.text;
      widget.produto.categoria = _categoriaController.text;
      widget.produto.valorEstimado = _valorEstimadoController.text;
      widget.produto.quantidade = int.tryParse(_quantidadeController.text) ?? 1;

      await _storage.saveProduto(widget.produto);

      Modular.to.pop();
    }
  }

  bool _isFieldEnabled(String fieldName) {
    if (widget.produto.isDanificado) return false;

    if (!widget.isVistoriaReview) return true;
    return widget.camposAlteradosPelaIA.contains(fieldName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isVistoriaReview ? 'Revisão da IA' : 'Editar Produto'),
        backgroundColor: widget.produto.isDanificado ? Colors.red : (widget.isVistoriaReview ? Colors.orange : null),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (widget.produto.fotoPath.isNotEmpty)
                SizedBox(
                    height: 200,
                    child: Image.file(File(widget.produto.fotoPath))
                ),
              const SizedBox(height: 16),

              // AVISO DE DANO
              if (widget.produto.isDanificado)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.red[100],
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8)
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 32),
                      SizedBox(width: 12),
                      Expanded(child: Text(
                        "ITEM DANIFICADO/COM DEFEITO.\nEdição bloqueada.",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ))
                    ],
                  ),
                )
              else if (widget.isVistoriaReview)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    "A IA detectou alterações. Verifique os campos.",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),

              _buildField(_nomeController, 'Nome', 'nome'),
              _buildField(_categoriaController, 'Categoria', 'categoria'),
              _buildField(_quantidadeController, 'Quantidade', 'quantidade', isNumber: true),
              _buildField(_valorEstimadoController, 'Valor', 'valor'),

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Modular.to.pop(),
                          child: const Text('Voltar')
                      )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _salvar,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: widget.produto.isDanificado ? Colors.red : null,
                              foregroundColor: widget.produto.isDanificado ? Colors.white : null
                          ),
                          child: Text(widget.produto.isDanificado ? 'Confirmar Avaria' : 'Salvar')
                      )
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, String fieldKey, {bool isNumber = false}) {
    final isEnabled = _isFieldEnabled(fieldKey);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        enabled: isEnabled,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
            labelText: label,
            filled: !isEnabled,
            fillColor: Colors.grey[200],
            border: const OutlineInputBorder()
        ),
        validator: (v) => v == null || v.isEmpty ? 'Campo obrigatório' : null,
      ),
    );
  }
}