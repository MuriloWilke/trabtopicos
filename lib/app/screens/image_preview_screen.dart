import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class ImagePreviewScreen extends StatelessWidget {
  final String imagePath;

  const ImagePreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Foto'),
      ),
      body: Center(
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
        ),
      ),
      bottomNavigationBar: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
                icon: const Icon(Icons.close, color: Colors.redAccent),
                label: Text('Refazer', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                onPressed: () {
                  Modular.to.pop(null);
                }
            ),

            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Usar Foto'),
              onPressed: () {
                Modular.to.pop(imagePath);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}