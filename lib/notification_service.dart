import 'dart:async';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Stream controllers para diferentes eventos
  final StreamController<bool> _reviewAddedController = StreamController<bool>.broadcast();
  final StreamController<bool> _imageAddedController = StreamController<bool>.broadcast();

  // Getters para los streams
  Stream<bool> get reviewAdded => _reviewAddedController.stream;
  Stream<bool> get imageAdded => _imageAddedController.stream;

  // Métodos para notificar eventos
  void notifyReviewAdded() {
    _reviewAddedController.add(true);
  }

  void notifyImageAdded() {
    _imageAddedController.add(true);
  }

  // Limpiar recursos
  void dispose() {
    _reviewAddedController.close();
    _imageAddedController.close();
  }
}
