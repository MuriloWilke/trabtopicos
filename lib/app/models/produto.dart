import 'package:uuid/uuid.dart';

class Produto {
  final String id;
  final String unidadeId;
  final String fotoPath;
  String nome;
  String categoria;
  String valorEstimado;
  String estado;
  int quantidade;
  bool isChecked;

  Produto({
    String? id,
    required this.unidadeId,
    required this.fotoPath,
    required this.nome,
    required this.categoria,
    required this.valorEstimado,
    required this.estado,
    this.quantidade = 1,
    this.isChecked = false,
  }) : id = id ?? const Uuid().v4();

  factory Produto.fromJson(Map<String, dynamic> json, String path) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      return false;
    }

    return Produto(
      id: json['id'],
      unidadeId: json['unidadeId'] ?? '',
      fotoPath: path.isNotEmpty ? path : (json['fotoPath'] ?? ''),
      nome: json['nome'] ?? 'Nome Desconhecido',
      categoria: json['categoria'] ?? 'Categoria Desconhecida',
      valorEstimado: json['valor_estimado'] ?? json['valorEstimado'] ?? '0',
      estado: json['estado'] ?? 'Estado Desconhecido',
      quantidade: json['quantidade'] is int
          ? json['quantidade']
          : int.tryParse(json['quantidade'].toString()) ?? 1,
      isChecked: parseBool(json['isChecked']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unidadeId': unidadeId,
      'fotoPath': fotoPath,
      'nome': nome,
      'categoria': categoria,
      'valorEstimado': valorEstimado,
      'estado': estado,
      'quantidade': quantidade,
      'isChecked': isChecked ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'unidadeId': unidadeId,
      'fotoPath': fotoPath,
      'nome': nome,
      'categoria': categoria,
      'valorEstimado': valorEstimado,
      'estado': estado,
      'quantidade': quantidade,
      'isChecked': isChecked,
    };
  }

  Map<String, dynamic> toAIJson() {
    return {
      'uuid': id,
      'nome': nome,
      'categoria': categoria,
      'quantidade': quantidade,
      'estado': estado,
      'checked': isChecked,
    };
  }
}