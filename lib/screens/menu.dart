import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import 'historico_ia.dart';
import 'ia_page.dart';
import 'personagens_list.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => MenuOptionState();
}

class MenuOptionState extends State<MenuOptions> {
  static const Color verdeEscuro = Color(0xFF1F5D50);
  final UserService _userService = UserService();
  late final Future<UserModel?> _user = _userService.getUser();
  final PageController pc = PageController();

  final List<String> paginas = ['Meus personagens', 'Assistente IA', 'Histórico da IA'];
  final List<IconData> icones = [Icons.shield_outlined, Icons.auto_awesome, Icons.history];
  int paginaAtual = 0;

  @override
  void dispose() {
    pc.dispose();
    super.dispose();
  }

  void irParaPagina(int pagina) {
    Navigator.pop(context); // fecha o drawer
    pc.jumpToPage(pagina);
  }

  Future<void> sair() async {
    Navigator.pop(context);
    try {
      await FirebaseAuth.instance.signOut(); // AuthScreen volta ao login
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível sair: ${e.code}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(paginas[paginaAtual])),
      drawer: Drawer(
        backgroundColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
        ),
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.horizontal(right: Radius.circular(20)),
            gradient: LinearGradient(
              colors: [Color(0xFF173E35), Color(0xFF2E7D6B), Color(0xFF6C8C7D)],
              stops: [0.0, 0.55, 1.0],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 38, color: colors.primary),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<UserModel?>(
                        future: _user,
                        builder: (context, snapshot) {
                          final nome = snapshot.data?.displayName.trim();
                          return Text(
                            (nome != null && nome.isNotEmpty)
                                ? nome
                                : (user?.email ?? 'Aventureiro'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, indent: 16, endIndent: 16, height: 1),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (var i = 0; i < paginas.length; i++)
                        buildMenuItem(
                          icon: icones[i],
                          text: paginas[i],
                          selecionado: paginaAtual == i,
                          onTap: () => irParaPagina(i),
                        ),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, indent: 16, endIndent: 16),
                buildMenuItem(icon: Icons.logout, text: 'Sair', onTap: sair),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: pc,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (p) => setState(() => paginaAtual = p),
        children: const [
          PersonagensListPage(),
          IaPage(),
          HistoricoIaPage(),
        ],
      ),
    );
  }

  Widget buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    bool selecionado = false,
  }) {
    final Color corConteudo = selecionado ? verdeEscuro : Colors.white;
    final Color corFundo =
        selecionado ? Colors.white : Colors.white.withValues(alpha: 0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Material(
        color: corFundo,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
            child: Row(
              children: [
                Icon(icon, color: corConteudo, size: 22),
                const SizedBox(width: 14),
                Text(
                  text,
                  style: TextStyle(
                    color: corConteudo,
                    fontSize: 15,
                    fontWeight: selecionado ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
