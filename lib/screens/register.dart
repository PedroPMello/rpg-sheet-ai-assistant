import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';

class RegisterScreen extends StatefulWidget {
  final Function()? onTap;
  const RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final UserService _userService = UserService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (_passwordController.text != _confirmController.text) {
      _mensagem('As senhas não conferem!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _userService.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // AuthScreen observa authStateChanges e abre o menu.
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'email-already-in-use' => 'Este email já está cadastrado!',
        'invalid-email' => 'Informe um email válido!',
        'weak-password' => 'A senha precisa ter ao menos 6 caracteres!',
        _ => 'Não foi possível registrar: ${e.code}',
      };
      _mensagem(message);
    } catch (e) {
      _mensagem('Não foi possível registrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mensagem(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 243, 243),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                SizedBox(
                  height: 100,
                  child: ClipOval(child: Image.asset('assets/logos/logo.png')),
                ),
                const SizedBox(height: 10),
                Text(
                  'Crie sua conta para guardar seus personagens.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 16),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: _nameController,
                  hintText: 'Nome',
                  icon: const Icon(Icons.person_outline),
                  obscureText: false,
                  capitalization: true,
                ),
                const SizedBox(height: 15),
                MyTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: const Icon(Icons.email_outlined),
                  obscureText: false,
                  capitalization: false,
                ),
                const SizedBox(height: 15),
                MyTextField(
                  controller: _passwordController,
                  hintText: 'Senha',
                  icon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  capitalization: false,
                ),
                const SizedBox(height: 15),
                MyTextField(
                  controller: _confirmController,
                  hintText: 'Confirmar senha',
                  icon: const Icon(Icons.lock_outline),
                  obscureText: true,
                  capitalization: false,
                ),
                const SizedBox(height: 20),
                MyButton(
                  onPressed: _handleSignUp,
                  formKey: _formKey,
                  text: 'Registrar',
                ),
                if (_isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Já tem conta? ',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Faça login',
                        style: TextStyle(
                          color: Color(0xffE01C2F),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
