import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ai_service.dart';
import '../services/historico_ia_service.dart';

/// Abre um painel que gera a resposta do Gemini em streaming
/// e salva a interação no histórico (Firestore) ao terminar.
Future<void> pedirAjudaIa(
  BuildContext context, {
  required String titulo,
  required String pergunta, // texto curto que aparece no histórico
  required String prompt, // texto completo enviado ao Gemini
  required String origem,
  String? personagemId,
  String? personagemNome,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => AjudaIaSheet(
      titulo: titulo,
      pergunta: pergunta,
      prompt: prompt,
      origem: origem,
      personagemId: personagemId,
      personagemNome: personagemNome,
    ),
  );
}

class AjudaIaSheet extends StatefulWidget {
  final String titulo;
  final String pergunta;
  final String prompt;
  final String origem;
  final String? personagemId;
  final String? personagemNome;

  const AjudaIaSheet({
    super.key,
    required this.titulo,
    required this.pergunta,
    required this.prompt,
    required this.origem,
    this.personagemId,
    this.personagemNome,
  });

  @override
  State<AjudaIaSheet> createState() => _AjudaIaSheetState();
}

class _AjudaIaSheetState extends State<AjudaIaSheet> {
  final _ai = AiService();
  final _historico = HistoricoIaService();
  StreamSubscription<String>? _sub;

  String _resposta = '';
  String? _erro;
  bool _gerando = true;

  @override
  void initState() {
    super.initState();
    _sub = _ai.gerarEmStream(widget.prompt).listen(
          (pedaco) => setState(() => _resposta += pedaco),
          onError: (Object e) => setState(() {
            _erro = 'Erro ao gerar resposta: $e';
            _gerando = false;
          }),
          onDone: _finalizar,
          cancelOnError: true,
        );
  }

  Future<void> _finalizar() async {
    if (mounted) setState(() => _gerando = false);
    if (_resposta.isEmpty) return;
    try {
      await _historico.salvar(
        pergunta: widget.pergunta,
        resposta: _resposta,
        origem: widget.origem,
        personagemId: widget.personagemId,
        personagemNome: widget.personagemNome,
      );
    } catch (_) {
      // Falha ao salvar o histórico não deve atrapalhar a resposta.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(widget.titulo, style: theme.textTheme.titleLarge),
                ),
              ],
            ),
            if (_gerando)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: _erro != null
                    ? Text(_erro!, style: TextStyle(color: theme.colorScheme.error))
                    : SelectableText(_resposta.isEmpty ? 'Pensando...' : _resposta),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!_gerando && _resposta.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _resposta));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Resposta copiada')),
                      );
                    },
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Fechar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
