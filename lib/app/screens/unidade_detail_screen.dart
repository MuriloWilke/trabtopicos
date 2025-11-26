import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../core/services/ai_service.dart';
import '../core/services/storage_service.dart';
import '../models/produto.dart';
import '../models/unidade.dart';
import 'image_picker_screen.dart';

class UnidadeDetailScreen extends StatefulWidget {
  final Unidade unidade;
  const UnidadeDetailScreen({super.key, required this.unidade});

  @override
  State<UnidadeDetailScreen> createState() => _UnidadeDetailScreenState();
}

class _UnidadeDetailScreenState extends State<UnidadeDetailScreen> {
  final StorageService _storage = Modular.get<StorageService>();
  final AiService _aiService = Modular.get<AiService>();

  List<Produto> _produtos = [];
  bool _isLoading = true;
  bool _isProcessingAI = false;

  @override
  void initState() {
    super.initState();
    _loadProdutos();
  }

  Future<void> _loadProdutos() async {
    setState(() => _isLoading = true);
    final list = await _storage.getProdutos(widget.unidade.id);
    setState(() {
      _produtos = list;
      _isLoading = false;
    });
  }

  Future<void> _adicionarItem() async {
    final imagePath = await _tirarFoto();
    if (imagePath == null) return;

    setState(() => _isProcessingAI = true);

    try {
      final jsonResult = await _aiService.analisarImagemCadastro(imagePath);

      if (jsonResult != null) {
        final novoProduto = Produto.fromJson(jsonResult, imagePath);
        final produtoVinculado = Produto(
            unidadeId: widget.unidade.id,
            fotoPath: imagePath,
            nome: novoProduto.nome,
            categoria: novoProduto.categoria,
            valorEstimado: novoProduto.valorEstimado,
            estado: novoProduto.estado,
            quantidade: novoProduto.quantidade
        );

        _abrirTelaEdicao(produtoVinculado, false, []);
      } else {
        _showError('A IA não conseguiu identificar o produto.');
      }
    } catch (e) {
      _showError('Erro: $e');
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  Future<void> _iniciarVistoria() async {
    if (_produtos.isEmpty) {
      _showError('Não há itens nesta unidade para vistoriar.');
      return;
    }

    final imagePath = await _tirarFoto();
    if (imagePath == null) return;

    setState(() => _isProcessingAI = true);

    try {
      final resultadoIA = await _aiService.realizarVistoria(imagePath, _produtos);

      if (resultadoIA != null) {
        _processarRetornoVistoria(resultadoIA, imagePath);
      } else {
        _showError('Falha na análise da vistoria.');
      }
    } catch (e) {
      log(e.toString());
      _showError('Erro na vistoria: $e');
    } finally {
      setState(() => _isProcessingAI = false);
    }
  }

  void _processarRetornoVistoria(Map<String, dynamic> dados, String imagePath) async {
    if (dados['status'] == 'erro') {
      _showError(dados['mensagem'] ?? 'Item não pertence a esta unidade!');
      return;
    }

    if (dados['uuid'] != null) {
      if (dados['status'] == 'already_checked') {
        _showWarning('Este item já foi vistoriado anteriormente!');
        return;
      }

      final existingIndex = _produtos.indexWhere((p) => p.id == dados['uuid']);

      if (existingIndex >= 0) {
        final produtoOriginal = _produtos[existingIndex];

        List<String> camposAlterados = [];
        if (dados['quantidade'].toString() != produtoOriginal.quantidade.toString()) camposAlterados.add('quantidade');
        if (dados['estado'] != produtoOriginal.estado) camposAlterados.add('estado');

        final produtoAtualizado = Produto(
            id: produtoOriginal.id,
            unidadeId: widget.unidade.id,
            fotoPath: imagePath,
            nome: produtoOriginal.nome,
            categoria: produtoOriginal.categoria,
            valorEstimado: produtoOriginal.valorEstimado,
            estado: dados['estado'] ?? produtoOriginal.estado,
            quantidade: dados['quantidade'] is int ? dados['quantidade'] : int.tryParse(dados['quantidade'].toString()) ?? produtoOriginal.quantidade,
            isChecked: true
        );

        if (camposAlterados.isNotEmpty || dados['status'] == 'changed') {
          _abrirTelaEdicao(produtoAtualizado, true, camposAlterados);
        } else {
          await _storage.saveProduto(produtoAtualizado);
          _loadProdutos();
          _showMessage('Item validado com sucesso!');
        }
      }
    }
    else {
      _showError('Item não identificado na lista de estoque.');
    }
  }

  Future<String?> _tirarFoto() async {
    final result = await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TakePictureScreen())
    );
    return result as String?;
  }

  Future<void> _abrirTelaEdicao(Produto produto, bool isVistoria, List<String> camposAlterados) async {
    await Modular.to.pushNamed('/produto-edit', arguments: {
      'produto': produto,
      'isVistoria': isVistoria,
      'camposAlterados': camposAlterados
    });
    _loadProdutos();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red));
  void _showMessage(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  void _showWarning(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.orange));

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text(widget.unidade.nome)),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Itens: ${_produtos.length} / Verificados: ${_produtos.where((p)=>p.isChecked).length}'),
                    ElevatedButton.icon(
                      icon: const Icon(
                        Icons.fact_check,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Vistoria',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                      onPressed: _iniciarVistoria,
                    )
                  ],
                ),
              ),
              Expanded(
                child: _produtos.isEmpty
                    ? const Center(child: Text('Sem itens. Adicione o primeiro!'))
                    : ListView.builder(
                  itemCount: _produtos.length,
                  itemBuilder: (ctx, i) {
                    final p = _produtos[i];
                    return ListTile(
                      leading: p.isChecked
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.circle_outlined, color: Colors.grey),
                      title: Text(p.nome),
                      subtitle: Text('${p.quantidade} un - ${p.estado}'),
                      trailing: Text(p.valorEstimado),
                      onTap: () => _abrirTelaEdicao(p, false, []),
                    );
                  },
                ),
              )
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _adicionarItem,
            child: const Icon(Icons.add_a_photo),
          ),
        ),

        if (_isProcessingAI)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          )
      ],
    );
  }
}