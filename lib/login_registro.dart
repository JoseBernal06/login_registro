import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  Future<void> login() async {
    try {
      // Mostrar mensaje de intento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intentando conectar a Supabase...')),
      );
      
      await supabase.auth.signInWithPassword(
        email: emailController.text,
        password: passwordController.text,
      );
    } catch (e) {
      // Mostrar error más detallado
      String errorMessage = 'Error al iniciar sesión: $e';
      if (e.toString().contains('SocketException')) {
        errorMessage += '\n\nPROBLEMA DE CONEXIÓN:\n- Verifica tu WiFi\n- Cambia DNS a 8.8.8.8\n- Desactiva VPN/Proxy';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  Future<void> signup() async {
    try {
      // Mostrar mensaje de intento
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Intentando conectar a Supabase...')),
      );
      
      await supabase.auth.signUp(
        email: emailController.text,
        password: passwordController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa tu correo para confirmar tu cuenta.')),
      );
    } catch (e) {
      // Mostrar error más detallado
      String errorMessage = 'Error al registrarse: $e';
      if (e.toString().contains('SocketException')) {
        errorMessage += '\n\nPROBLEMA DE CONEXIÓN:\n- Verifica tu WiFi\n- Cambia DNS a 8.8.8.8\n- Desactiva VPN/Proxy';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  void guestAccess() {
    // Navegación como invitado sin autenticación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Accediendo como invitado')),
    );
    // Navegar a la página principal como invitado
    Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const HomePage(isGuestMode: true))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login, Registro y Acceso como Invitado')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Contraseña'), obscureText: true),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: login, child: const Text('Iniciar sesión')),
            TextButton(onPressed: signup, child: const Text('Registrarse')),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: guestAccess, 
              child: const Text('Continuar como Invitado'),
            ),
          ],
        ),
      ),
    );
  }
}