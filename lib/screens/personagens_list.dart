import 'package:flutter/material.dart';
import '../models/personagem.dart';
import '../services/personagem_service.dart';
import 'personagem_detalhe.dart';
import 'personagem_form.dart';

class PersonagensListPage extends StatefulWidget {
  const PersonagensListPage({super.key});

  @override
  State<PersonagensListPage> createState() => _PersonagensListPageState();
}

class _PersonagensListPageState extends State<PersonagensListPage> {
  final _service = PersonagemService();
  late final Stream<List<Personagem>> _stream = _service.listar();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Personagem>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final lista = snapshot.data!;
          if (lista.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum personagem ainda.\nToque em "Novo personagem" para criar o primeiro!',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final p = lista[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(p.nome.isEmpty ? '?' : p.nome[0].toUpperCase()),
                  ),
                  title: Text(p.nome),
                  subtitle: Text('${p.raca} • ${p.classe} • Nível ${p.nivel}'),
                  trailing: Text('PV ${p.pvAtual}/${p.pvMax}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PersonagemDetalhePage(id: p.id!),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Novo personagem'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PersonagemFormPage()),
        ),
      ),
    );
  }
}
