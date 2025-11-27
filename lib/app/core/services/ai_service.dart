import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/produto.dart';

class AiService {
  final String _cadastroEndpoint = 'https://flowiseai-railway-production-dc27.up.railway.app/api/v1/prediction/93655f1e-1398-446b-9861-f5d40f5f491b';
  final String _vistoriaEndpoint = 'https://flowiseai-railway-production-dc27.up.railway.app/api/v1/prediction/ca8709fc-506f-4903-a1d0-72e63d81d639';

  Future<Map<String, dynamic>?> analisarImagemCadastro(String imagePath) async {
    log('--- Iniciando Análise de Cadastro ---');
    return _sendToFlowise(
        imagePath,
        "Analise esta imagem e extraia os dados do produto (nome, categoria, valor, quantidade).",
        _cadastroEndpoint
    );
  }

  Future<Map<String, dynamic>?> realizarVistoria(String imagePath, List<Produto> estoqueAtual) async {
    log('--- Iniciando Vistoria ---');
    final estoqueJson = estoqueAtual.map((p) => p.toAIJson()).toList();

    final prompt = """
      Estou fazendo uma vistoria de estoque.
      Aqui está a lista COMPLETA de itens do local (JSON): ${jsonEncode(estoqueJson)}.
      
      Analise a imagem enviada procurando por DEFEITOS, SUJEIRA, QUEBRAS ou DANOS:
      
      1. Se o item da imagem corresponde a um item da lista:
         - Retorne o UUID dele.
         - Se ele apresentar qualquer defeito, sujeira visível ou estiver quebrado: defina "isDanificado": true.
         - Se a quantidade mudou, ajuste o campo "quantidade".
         - Se estiver tudo perfeito: retorne status 'ok'.
         - Se houver dano ou mudança de quantidade: retorne status 'changed' e os campos na raiz do JSON.
      
      2. Se o item NÃO está na lista, retorne: { "status": "erro", "mensagem": "Item não pertence a esta unidade" }.
      
      Exemplo de retorno de item danificado:
      {
        "uuid": "...",
        "status": "changed",
        "isDanificado": true,
        "quantidade": 1
      }
    """;

    return _sendToFlowise(imagePath, prompt, _vistoriaEndpoint);
  }

  Future<Map<String, dynamic>?> _sendToFlowise(String imagePath, String question, String endpoint) async {
    try {
      log('Preparando envio para: $endpoint');
      log('Prompt enviado: $question');

      final imageFile = File(imagePath);
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final body = jsonEncode({
        "question": question,
        "uploads": [
          {
            "data": "data:image/jpeg;base64,$base64Image",
            "type": "file",
            "name": "upload.jpeg",
            "mime": "image/jpeg"
          }
        ]
      });

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 60));

      log('HTTP Status Code: ${response.statusCode}');
      log('HTTP Body Bruto: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String text = jsonResponse['text'] ?? '';

        final startIndex = text.indexOf('{');
        final endIndex = text.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          final cleanJson = text.substring(startIndex, endIndex + 1);
          log("JSON Limpo para parse: $cleanJson");
          try {
            return jsonDecode(cleanJson);
          } catch (e) {
            log("Erro ao fazer parse do JSON limpo: $e");
          }
        }
      }
    } catch (e) {
      log('EXCEÇÃO no AiService: $e');
    }
    return null;
  }
}