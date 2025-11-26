import 'package:uuid/uuid.dart';

class Unidade {
  final String id;
  String nome;

  Unidade({String? id, required this.nome}) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};

  factory Unidade.fromJson(Map<String, dynamic> json) {
    return Unidade(id: json['id'], nome: json['nome']);
  }
}