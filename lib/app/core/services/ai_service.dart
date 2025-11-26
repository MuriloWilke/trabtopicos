import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/produto.dart';

class AiService {
  final String _cadastroEndpoint = 'https://flowiseai-railway-production-dc27.up.railway.app/api/v1/prediction/93655f1e-1398-446b-9861-f5d40f5f491b';
  final String _vistoriaEndpoint = 'https://flowiseai-railway-production-dc27.up.railway.app/api/v1/prediction/ca8709fc-506f-4903-a1d0-72e63d81d639';

  Future<Map<String, dynamic>?> analisarImagemCadastro(String imagePath) async {
    return _sendToFlowise(
        imagePath,
        "Analise esta imagem e extraia os dados do produto (nome, categoria, valor, estado, quantidade).",
        _cadastroEndpoint
    );
  }

  Future<Map<String, dynamic>?> realizarVistoria(String imagePath, List<Produto> estoqueAtual) async {
    final estoqueJson = estoqueAtual.map((p) => p.toAIJson()).toList();

    final prompt = """
      Estou fazendo uma vistoria de estoque.
      Aqui está a lista COMPLETA de itens do local (JSON): ${jsonEncode(estoqueJson)}.
      Alguns itens já foram conferidos (checked: true).
      
      Analise a imagem enviada:
      1. Se o item da imagem corresponde a um item da lista (mesmo se checked: true), retorne o UUID dele.
         - Se ele já estava 'checked: true', adicione status: 'already_checked'.
         - Se houve mudança (ex: quantidade, estado, valor), retorne status: 'changed' e os campos alterados.
         - Se está tudo igual e não estava checked, retorne status: 'ok'.
      
      2. Se o item NÃO está na lista fornecida, retorne estritamente o json: { "status": "erro", "mensagem": "Item não pertence a esta unidade" }.
    """;

    return _sendToFlowise(imagePath, prompt, _vistoriaEndpoint);
  }

  Future<Map<String, dynamic>?> _sendToFlowise(String imagePath, String question, String endpoint) async {
    try {
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

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final String text = jsonResponse['text'] ?? '';
        log("Resposta da IA: $text");

        final startIndex = text.indexOf('{');
        final endIndex = text.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1) {
          final cleanJson = text.substring(startIndex, endIndex + 1);
          return jsonDecode(cleanJson);
        }
      } else {
        log('Erro Flowise ($endpoint): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Erro AI Service: $e');
    }
    return null;
  }
}