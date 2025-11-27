import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/produto.dart';
import '../../models/unidade.dart';

class StorageService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'estoque_app_v3.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE unidades(
            id TEXT PRIMARY KEY,
            nome TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE produtos(
            id TEXT PRIMARY KEY,
            unidadeId TEXT,
            fotoPath TEXT,
            nome TEXT,
            categoria TEXT,
            valorEstimado TEXT,
            quantidade INTEGER,
            isChecked INTEGER,
            isDanificado INTEGER, 
            FOREIGN KEY (unidadeId) REFERENCES unidades (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // --- UNIDADES ---

  Future<List<Unidade>> getUnidades() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('unidades');

    return List.generate(maps.length, (i) {
      return Unidade.fromJson(maps[i]);
    });
  }

  Future<void> saveUnidade(Unidade unidade) async {
    final db = await database;
    await db.insert(
      'unidades',
      unidade.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- PRODUTOS ---

  Future<List<Produto>> getProdutos(String unidadeId) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'produtos',
      where: 'unidadeId = ?',
      whereArgs: [unidadeId],
    );

    return List.generate(maps.length, (i) {
      return Produto.fromJson(maps[i], maps[i]['fotoPath'] as String? ?? '');
    });
  }

  Future<void> saveProduto(Produto produto) async {
    final db = await database;

    await db.insert(
      'produtos',
      produto.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteProduto(String produtoId) async {
    final db = await database;
    await db.delete(
      'produtos',
      where: 'id = ?',
      whereArgs: [produtoId],
    );
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('produtos');
    await db.delete('unidades');
  }
}