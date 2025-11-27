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

  Future<void> _deletarProduto(Produto produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Item'),
        content: Text('Tem certeza que deseja excluir "${produto.nome}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      await _storage.deleteProduto(produto.id);
      _loadProdutos();
    }
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
            quantidade: novoProduto.quantidade,
            isDanificado: false
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

        final novaQuantidade = dados['quantidade'] != null
            ? (dados['quantidade'] is int ? dados['quantidade'] : int.tryParse(dados['quantidade'].toString()) ?? produtoOriginal.quantidade)
            : produtoOriginal.quantidade;

        bool isDanificadoNovo = dados['isDanificado'] == true;
        if (dados['isDanificado'] == null) {
          isDanificadoNovo = produtoOriginal.isDanificado;
        }

        List<String> camposAlterados = [];
        if (novaQuantidade != produtoOriginal.quantidade) camposAlterados.add('quantidade');
        if (isDanificadoNovo != produtoOriginal.isDanificado) camposAlterados.add('isDanificado');

        final produtoAtualizado = Produto(
            id: produtoOriginal.id,
            unidadeId: widget.unidade.id,
            fotoPath: imagePath,
            nome: produtoOriginal.nome,
            categoria: produtoOriginal.categoria,
            valorEstimado: produtoOriginal.valorEstimado,
            quantidade: novaQuantidade,
            isChecked: true,
            isDanificado: isDanificadoNovo
        );

        if (dados['status'] == 'changed' || camposAlterados.isNotEmpty || isDanificadoNovo) {
          _abrirTelaEdicao(produtoAtualizado, true, camposAlterados);
        } else {
          await _storage.saveProduto(produtoAtualizado);
          _loadProdutos();
          _showMessage('Item validado com sucesso!');
        }
      } else {
        _showError('Erro interno: UUID retornado não encontrado na lista local.');
      }
    }
    else {
      final novoProduto = Produto.fromJson(dados, imagePath);
      final prodFinal = Produto(
          unidadeId: widget.unidade.id,
          fotoPath: imagePath,
          nome: novoProduto.nome,
          categoria: novoProduto.categoria,
          valorEstimado: novoProduto.valorEstimado,
          quantidade: novoProduto.quantidade,
          isChecked: true,
          isDanificado: dados['isDanificado'] == true
      );
      _abrirTelaEdicao(prodFinal, false, []);
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
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE0E0E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.priority_high,
                          color: Colors.black,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Não há itens cadastrados.\nAdicione o primeiro!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : ListView.separated(
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemCount: _produtos.length,
                  itemBuilder: (ctx, i) {
                    final p = _produtos[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: p.isDanificado
                          ? Container(
                        width: 32, height: 32,
                        decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      )
                          : (p.isChecked
                          ? const Icon(Icons.check_circle, color: Colors.green, size: 32)
                          : const Icon(Icons.circle_outlined, color: Colors.grey, size: 32)),

                      title: Text(
                          p.nome,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              decoration: p.isDanificado ? TextDecoration.lineThrough : null,
                              color: p.isDanificado ? Colors.grey : Colors.black87
                          )
                      ),

                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                              p.valorEstimado,
                              style: TextStyle(
                                  color: Colors.blue[800],
                                  fontWeight: FontWeight.w500
                              )
                          ),
                          Text('${p.quantidade} un', style: const TextStyle(fontSize: 12)),
                        ],
                      ),

                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deletarProduto(p),
                      ),

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