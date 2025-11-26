import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../models/produto.dart';

class ProdutoCache {
  static const _keyProdutos = 'produtosCadastrados';

  static Future<List<Produto>> carregarProdutos() async {
    final prefs = await SharedPreferences.getInstance();
    final produtosJson = prefs.getStringList(_keyProdutos) ?? [];

    return produtosJson.map((jsonString) {
      final Map<String, dynamic> map = json.decode(jsonString);
      return Produto.fromJson(map, map['fotoPath']);
    }).toList();
  }

  static Future<void> salvarProduto(Produto produto) async {
    final prefs = await SharedPreferences.getInstance();
    final produtosAtuais = await carregarProdutos();

    produtosAtuais.add(produto);

    final produtosJsonStrings = produtosAtuais
        .map((p) => json.encode(p.toJson()))
        .toList();

    await prefs.setStringList(_keyProdutos, produtosJsonStrings);
  }
}