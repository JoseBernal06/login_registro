import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  State<BlogPage> createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> imagenes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Obtener todas las imágenes de la tabla 'imagenes' ordenadas por fecha de creación
      final response = await supabase
          .from('imagenes')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        imagenes = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar imágenes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : imagenes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay imágenes aún',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ve a "Subir" para agregar tu primera imagen',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadImages,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: imagenes.length,
                    itemBuilder: (context, index) {
                      final imagen = imagenes[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen
                            Container(
                              width: double.infinity,
                              height: 250,
                              child: Image.network(
                                imagen['imagen'],
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.error, color: Colors.red, size: 50),
                                  );
                                },
                              ),
                            ),
                            // Descripción y fecha
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    imagen['descripcion'] ?? 'Sin descripción',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatDate(imagen['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: const Color.fromARGB(255, 147, 140, 140),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Botón centrado con funcionalidad de reseña
                                  Center(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        _showReviewDialog(context, imagen);
                                      },
                                      icon: const Icon(Icons.comment),
                                      label: const Text('Dejar reseña'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Fecha desconocida';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} atrás';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''} atrás';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''} atrás';
      } else {
        return 'Hace un momento';
      }
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  void _showReviewDialog(BuildContext context, Map<String, dynamic> imagen) {
    final TextEditingController commentController = TextEditingController();
    int selectedStars = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Dejar reseña'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Mostrar miniatura de la imagen
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(imagen['imagen']),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción de la imagen
                    Text(
                      imagen['descripcion'] ?? 'Sin descripción',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Rating con estrellas
                    const Text(
                      'Calificación:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedStars = index + 1;
                            });
                          },
                          child: Icon(
                            Icons.star,
                            size: 32,
                            color: index < selectedStars ? Colors.amber : Colors.grey[300],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    
                    // Campo de comentario
                    const Text(
                      'Comentario:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: commentController,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu comentario aquí...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                      maxLength: 200,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedStars > 0 && commentController.text.trim().isNotEmpty) {
                      // Aquí puedes agregar la lógica para guardar la reseña
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reseña enviada: $selectedStars estrellas'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor selecciona estrellas y escribe un comentario'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enviar reseña'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
