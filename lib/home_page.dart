import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'blog_page.dart';
import 'upload_page.dart';
import 'reviews_page.dart';
import 'login_registro.dart';

class HomePage extends StatefulWidget {
  final bool isGuestMode;
  
  const HomePage({super.key, this.isGuestMode = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final supabase = Supabase.instance.client;

  final List<Widget> _pages = [
    const BlogPage(),
    const UploadPage(),
    const ReviewsPage(),
  ];

  final List<String> _titles = [
    'Blog',
    'Agregar',
    'Reseñas',
  ];

  @override
  void initState() {
    super.initState();
    // Mostrar mensaje de bienvenida si es modo invitado
    if (widget.isGuestMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGuestWelcomeMessage();
      });
    }
  }

  void _showGuestWelcomeMessage() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.person_outline, size: 48, color: Colors.blue),
          title: const Text('¡Bienvenido, Invitado!'),
          content: const Text(
            'Has accedido en modo invitado. Puedes explorar la aplicación, '
            'pero algunas funciones pueden estar limitadas. '
            'Considera registrarte para acceder a todas las características.',
          ),
          actions: [
            TextButton(
              child: const Text('Entendido'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout() async {
    try {
      if (widget.isGuestMode) {
        // Si es modo invitado, simplemente navegar a login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has salido del modo invitado')),
        );
      } else {
        // Si es usuario autenticado, cerrar sesión en Supabase
        await supabase.auth.signOut();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cerrar sesión: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(_titles[_selectedIndex]),
            if (widget.isGuestMode) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'INVITADO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
            tooltip: widget.isGuestMode ? 'Salir del modo invitado' : 'Cerrar sesión',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Blog',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Agregar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review),
            label: 'Reseñas',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.isGuestMode ? 'Salir del modo invitado' : 'Cerrar sesión'),
          content: Text(widget.isGuestMode 
            ? '¿Quieres salir del modo invitado y volver a la pantalla de login?'
            : '¿Estás seguro de que quieres cerrar sesión?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(widget.isGuestMode ? 'Salir' : 'Cerrar sesión'),
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
            ),
          ],
        );
      },
    );
  }
}