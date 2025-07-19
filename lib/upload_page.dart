import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final TextEditingController descriptionController = TextEditingController();
  final notificationService = NotificationService();

  Future<void> pickAndUploadImage(BuildContext context) async {
    final supabase = Supabase.instance.client;

    // Verificar que el usuario haya ingresado una descripción
    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa una descripción para la imagen')),
      );
      return;
    }

    // Permitir selección de una sola imagen
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      
      if (file.bytes != null) {
        // Mostrar diálogo de progreso
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Subiendo imagen...'),
                ],
              ),
            );
          },
        );

        try {
          final fileBytes = file.bytes!;
          final fileName = file.name;
          // Generar un nombre único para el archivo
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final uniqueFileName = '${timestamp}_$fileName';

          // Subir imagen al bucket 'deber'
          await supabase.storage.from('deber').uploadBinary(uniqueFileName, fileBytes);

          // Obtener la URL pública de la imagen
          final imageUrl = supabase.storage.from('deber').getPublicUrl(uniqueFileName);

          // Obtener el usuario actual
          final user = supabase.auth.currentUser;
          if (user == null) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error: Usuario no autenticado'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // Guardar los datos en la tabla 'deber_tabla'
          await supabase.from('deber_tabla').insert({
            'descripcion': descriptionController.text.trim(),
            'imagen': imageUrl,
            'created_at': DateTime.now().toIso8601String(),
            'user_id': user.id, // Guardar el ID del usuario
          });

          // Cerrar diálogo de progreso
          Navigator.of(context).pop();

          // Notificar que se agregó una nueva imagen
          notificationService.notifyImageAdded();

          // Mostrar resultado exitoso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Imagen y descripción guardadas exitosamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          
          // Limpiar los campos después del éxito
          descriptionController.clear();
          
        } catch (e) {
          // Cerrar diálogo de progreso
          Navigator.of(context).pop();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar imagen: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se seleccionó ninguna imagen')),
      );
    }
  }

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sube una imagen con su descripción',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción de la imagen',
                hintText: 'Describe tu imagen...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => pickAndUploadImage(context),
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Seleccionar y subir imagen'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}