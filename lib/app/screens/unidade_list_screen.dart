import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import '../core/services/storage_service.dart';
import '../models/unidade.dart';

class UnidadeListScreen extends StatefulWidget {
  const UnidadeListScreen({super.key});

  @override
  State<UnidadeListScreen> createState() => _UnidadeListScreenState();
}

class _UnidadeListScreenState extends State<UnidadeListScreen> {
  final StorageService _storage = Modular.get<StorageService>();
  List<Unidade> _unidades = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnidades();
  }

  Future<void> _loadUnidades() async {
    final list = await _storage.getUnidades();
    setState(() {
      _unidades = list;
      _isLoading = false;
    });
  }

  void _addUnidade() {
    final nomeController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Unidade'),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(hintText: 'Nome do Estoque/Unidade'),
        ),
        actions: [
          TextButton(onPressed: () => Modular.to.pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              if (nomeController.text.isNotEmpty) {
                final nova = Unidade(nome: nomeController.text);
                await _storage.saveUnidade(nova);
                Modular.to.pop();
                _loadUnidades();
              }
            },
            child: const Text('Criar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Minhas Unidades')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _unidades.isEmpty
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
              'Nenhuma unidade cadastrada.\nCrie a primeira!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _unidades.length,
        itemBuilder: (ctx, i) {
          final u = _unidades[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.warehouse, color: Colors.blue),
              title: Text(u.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${u.id.substring(0, 8)}...'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                Modular.to.pushNamed('/unidade-detail', arguments: u);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUnidade,
        child: const Icon(Icons.add),
      ),
    );
  }
}