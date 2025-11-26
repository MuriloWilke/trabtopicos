import 'dart:developer';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_modular/flutter_modular.dart';

import '../models/produto.dart';
import 'image_preview_screen.dart';

late List<CameraDescription> _cameras;

Future<void> initializeCameras() async {
  try {
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    log("Erro ao carregar câmeras: $e");
  }
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  State<TakePictureScreen> createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    final rearCamera = _cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => _cameras.first,
    );

    _controller = CameraController(
      rearCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        _controller.setFlashMode(FlashMode.off);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Tirar Foto do Produto'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return SizedBox(
              width: size.width,
              height: size.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.previewSize!.height,
                  height: _controller.value.previewSize!.width,
                  child: CameraPreview(_controller),
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();

            if (mounted) {
              final confirmedPath = await Modular.to.push(
                MaterialPageRoute(
                  builder: (ctx) => ImagePreviewScreen(imagePath: image.path),
                ),
              );

              if (confirmedPath is String) {
                Modular.to.pop(confirmedPath);
              }
            }
          } catch (e) {
            log('Erro ao tirar foto: $e');
            if (mounted) {
              Modular.to.pop(null);
            }
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

Future<Produto?> tirarFotoEProcessar() async {
  final file = await Modular.to.push(
    MaterialPageRoute(builder: (context) => const TakePictureScreen()),
  );

  if (file == null) return null;
  final imagePath = file as String;

  const String flowiseEndpoint = 'https://flowiseai-railway-production-dc27.up.railway.app/api/v1/prediction/93655f1e-1398-446b-9861-f5d40f5f491b';

  try {
    final imageFile = File(imagePath);
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final body = jsonEncode({
      "question": "Analise esta imagem.",
      "uploads": [
        {
          "data": "data:image/jpeg;base64,$base64Image",
          "type": "file",
          "name": "image_upload.jpeg",
          "mime": "image/jpeg"
        }
      ]
    });

    final response = await http.post(
      Uri.parse(flowiseEndpoint),
      headers: {
        'Content-Type': 'application/json',
      },
      body: body,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final jsonResponse = response.body;
      log('Resposta bruta do Flowise: $jsonResponse');

      try {
        final Map<String, dynamic> flowiseObject = json.decode(jsonResponse);
        final String llmResponseText = flowiseObject['text'] ?? '';

        log('Texto da LLM extraído: $llmResponseText');

        final startIndex = llmResponseText.indexOf('{');
        final endIndex = llmResponseText.lastIndexOf('}');

        if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
          final rawJson = llmResponseText.substring(startIndex, endIndex + 1);
          log('JSON LIMPO extraído: $rawJson');
          final Map<String, dynamic> dadosDoObjeto = json.decode(rawJson);
          log('JSON LIMPO parseado com sucesso.');
          return Produto.fromJson(dadosDoObjeto, imagePath);
        }

        log('ERRO: Não foi possível extrair o JSON limpo da resposta da LLM.');
        return null;
      } catch (e) {
        log('Erro fatal ao processar a resposta: $e');
        return null;
      }
    } else {
      log('Erro na API do Flowise: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    log('Erro durante a comunicação: $e');
    return null;
  }
}