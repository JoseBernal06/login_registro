import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_service.dart';
import 'dart:async';

class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final supabase = Supabase.instance.client;
  final notificationService = NotificationService();
  List<Map<String, dynamic>> reviews = [];
  bool isLoading = true;
  StreamSubscription<bool>? _reviewSubscription;

  @override
  void initState() {
    super.initState();
    _loadReviews();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // Escuchar cuando se agregan nuevas reseñas
    _reviewSubscription = notificationService.reviewAdded.listen((_) {
      _loadReviews(); // Recargar la lista de reseñas
    });
  }

  @override
  void dispose() {
    _reviewSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Obtener todas las reseñas ordenadas por fecha
      final response = await supabase
          .from('reviews')
          .select('*')
          .order('created_at', ascending: false);

      setState(() {
        reviews = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reseñas: $e')),
        );
      }
    }
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          Icons.star,
          size: 20,
          color: index < rating ? Colors.amber : Colors.grey[300],
        );
      }),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reviews.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay reseñas aún',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ve a "Galería" para dejar la primera reseña',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReviews,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con calificación y fecha
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStarRating(review['rating'] ?? 0),
                                  Text(
                                    _formatDate(review['created_at']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Comentario de la reseña
                              Text(
                                review['comment'] ?? 'Sin comentario',
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
