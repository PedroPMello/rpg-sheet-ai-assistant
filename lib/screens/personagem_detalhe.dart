import 'package:flutter/material.dart';
import '../components/ajuda_ia_sheet.dart';
import '../core/dnd_regras.dart';
import '../models/personagem.dart';
import '../services/personagem_service.dart';
import 'personagem_form.dart';

/// Ficha completa (READ) com edição, exclusão e PV rápidos.
class PersonagemDetalhePage extends StatefulWidget {
  final String id;
  const PersonagemDetalhePage({super.key, required this.id});

  @override
  State<PersonagemDetalhePage> createState() => _PersonagemDetalhePageState();
}

class _PersonagemDetalhePageState extends State<PersonagemDetalhePage> {
  final _service = PersonagemService();
  late final Stream<Personagem?> _stream = _service.observar(widget.id);

  Future<void> _excluir(Personagem p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Excluir personagem?'),
        content: Text('${p.nome} será removido permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _service.excluir(p.id!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _aviso('Erro ao excluir: $e');
    }
  }

  Future<void> _pv(Personagem p, int valor) async {
    try {
      await _service.atualizarPv(p.id!, valor);
    } catch (e) {
      _aviso('Erro ao atualizar PV: $e');
    }
  }

  void _revisarComIa(Personagem p) {
    pedirAjudaIa(
      context,
      titulo: 'Revisão da IA',
      pergunta: 'Revisão da ficha de ${p.nome}',
      origem: 'revisao',
      personagemId: p.id,
      personagemNome: p.nome,
      prompt: 'Revise esta ficha de D&D 5e e dê sugestões para um jogador iniciante: '
          'pontos fortes, possíveis erros ou incoerências com as regras, '
          'melhorias de atributos/perícias/equipamento e dicas de como '
          'interpretar o personagem.\n\n${p.resumo()}\n'
          'História: ${p.historia.isEmpty ? "(não escrita)" : p.historia}',
    );
  }

  void _aviso(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Personagem?>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Erro: ${snapshot.error}')),
          );
        }
        final p = snapshot.data;
        if (p == null) {
          // aguardando OU documento excluído
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : const Text('Personagem não encontrado'),
            ),
          );
        }
        return _ficha(p);
      },
    );
  }

  Widget _ficha(Personagem p) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nome),
        actions: [
          IconButton(
            tooltip: 'Editar',
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PersonagemFormPage(personagem: p)),
            ),
          ),
          IconButton(
            tooltip: 'Excluir',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _excluir(p),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${p.raca} ${p.classe} • Nível ${p.nivel}',
            style: theme.textTheme.titleLarge,
          ),
          if (p.antecedente.isNotEmpty || p.alinhamento.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                [p.antecedente, p.alinhamento].where((s) => s.isNotEmpty).join(' • '),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 16),

          // Pontos de vida
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Pontos de vida', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('${p.pvAtual} / ${p.pvMax}', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: p.pvMax == 0
                        ? 0
                        : (p.pvAtual / p.pvMax).clamp(0.0, 1.0).toDouble(),
                    minHeight: 8,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filledTonal(
                        icon: const Icon(Icons.remove),
                        onPressed: p.pvAtual > 0 ? () => _pv(p, p.pvAtual - 1) : null,
                      ),
                      const SizedBox(width: 12),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.add),
                        onPressed: p.pvAtual < p.pvMax ? () => _pv(p, p.pvAtual + 1) : null,
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        icon: const Icon(Icons.hotel),
                        label: const Text('Descanso longo'),
                        onPressed: p.pvAtual < p.pvMax ? () => _pv(p, p.pvMax) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // CA, deslocamento, proficiência
          Row(
            children: [
              _estatistica('CA', '${p.ca}'),
              _estatistica('Desloc.', '${p.deslocamento} ft'),
              _estatistica('Prof.', DndRegras.formatarMod(p.bonusProficiencia)),
            ],
          ),
          const SizedBox(height: 8),

          // Atributos
          Text('Atributos', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in DndRegras.chavesAtributos)
                SizedBox(
                  width: 100,
                  child: Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Text(DndRegras.siglas[k]!, style: theme.textTheme.labelLarge),
                          Text(
                            DndRegras.formatarMod(p.mod(k)),
                            style: theme.textTheme.headlineMedium,
                          ),
                          Text('${p.atributos[k]}'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Perícias
          Text('Perícias proficientes', style: theme.textTheme.titleMedium),
          if (p.pericias.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text('Nenhuma selecionada.'),
            )
          else
            for (final nome in p.pericias)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('$nome (${DndRegras.siglas[DndRegras.pericias[nome]] ?? "?"})'),
                trailing: Text(
                  DndRegras.formatarMod(
                    p.mod(DndRegras.pericias[nome] ?? 'for') + p.bonusProficiencia,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),

          if (p.equipamento.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Equipamento', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(p.equipamento),
          ],
          if (p.historia.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('História', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(p.historia),
          ],

          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Revisar ficha com a IA'),
            onPressed: () => _revisarComIa(p),
          ),
        ],
      ),
    );
  }

  Widget _estatistica(String rotulo, String valor) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Text(rotulo, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(valor, style: theme.textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
