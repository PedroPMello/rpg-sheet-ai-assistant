import 'package:flutter/material.dart';
import '../models/interacao_ia.dart';
import '../services/historico_ia_service.dart';

/// Histórico de interações com o Gemini (READ / DELETE).
class HistoricoIaPage extends StatefulWidget {
  const HistoricoIaPage({super.key});

  @override
  State<HistoricoIaPage> createState() => _HistoricoIaPageState();
}

class _HistoricoIaPageState extends State<HistoricoIaPage> {
  final _service = HistoricoIaService();
  late final Stream<List<InteracaoIa>> _stream = _service.listar();

  String _rotuloOrigem(String o) => switch (o) {
        'criacao' => 'Criação de ficha',
        'revisao' => 'Revisão de ficha',
        _ => 'Assistente',
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<InteracaoIa>>(
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
                  'Suas conversas com a IA aparecerão aqui.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final it = lista[i];
              final sobre = it.personagemNome == null ? '' : ' • ${it.personagemNome}';
              return Card(
                child: ExpansionTile(
                  title: Text(it.pergunta, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${_rotuloOrigem(it.origem)}$sobre • ${it.data}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  expandedCrossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(it.resposta),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Excluir'),
                        onPressed: () => _service.excluir(it.id),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
