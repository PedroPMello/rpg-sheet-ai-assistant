import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/personagem.dart';
import '../services/ai_service.dart';
import '../services/historico_ia_service.dart';
import '../services/personagem_service.dart';

/// Assistente de D&D com Gemini. Cada resposta concluída é salva
/// no Firestore (users/{uid}/historico_ia).
class IaPage extends StatefulWidget {
  const IaPage({super.key});

  @override
  State<IaPage> createState() => _IaPageState();
}

class _IaPageState extends State<IaPage> {
  final _service = AiService();
  final _historico = HistoricoIaService();
  final _personagemService = PersonagemService();
  late final Stream<List<Personagem>> _personagensStream = _personagemService.listar();
  final _textController = TextEditingController();
  StreamSubscription<String>? _sub;

  List<Personagem> _personagens = [];
  String? _contextoId; // personagem usado como contexto (opcional)

  String _ultimoPrompt = '';
  String _resposta = '';
  String? _erro;
  bool _carregando = false;

  static const _sugestoes = [
    'Como funciona um teste de resistência?',
    'Qual classe é boa para iniciantes?',
    'Explique vantagem e desvantagem',
    'Como calcular o modificador de atributo?',
  ];

  bool get _temConteudo => _ultimoPrompt.isNotEmpty;

  Future<void> _enviar([String? texto]) async {
    final pergunta = (texto ?? _textController.text).trim();
    if (pergunta.isEmpty || _carregando) return;

    final contexto = _personagens.where((p) => p.id == _contextoId).firstOrNull;
    final prompt = contexto == null
        ? pergunta
        : 'Contexto - meu personagem de D&D 5e:\n${contexto.resumo()}\n\n'
            'Pergunta: $pergunta';

    await _sub?.cancel();
    _textController.clear();
    if (mounted) FocusScope.of(context).unfocus();

    setState(() {
      _ultimoPrompt = pergunta;
      _resposta = '';
      _erro = null;
      _carregando = true;
    });

    _sub = _service.gerarEmStream(prompt).listen(
      (pedaco) => setState(() => _resposta += pedaco),
      onError: (Object e) => setState(() {
        _erro = _mensagemErro(e);
        _carregando = false;
      }),
      onDone: () {
        setState(() => _carregando = false);
        _salvarHistorico(pergunta, contexto);
      },
      cancelOnError: true,
    );
  }

  Future<void> _salvarHistorico(String pergunta, Personagem? contexto) async {
    if (_resposta.isEmpty) return;
    try {
      await _historico.salvar(
        pergunta: pergunta,
        resposta: _resposta,
        origem: 'assistente',
        personagemId: contexto?.id,
        personagemNome: contexto?.nome,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar no histórico: $e')),
      );
    }
  }

  Future<void> _parar() async {
    await _sub?.cancel();
    _sub = null;
    setState(() => _carregando = false);
  }

  void _copiar() {
    Clipboard.setData(ClipboardData(text: _resposta));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Resposta copiada')),
    );
  }

  String _mensagemErro(Object e) {
    final msg = e.toString();
    final lower = msg.toLowerCase();
    if (lower.contains('high demand') || lower.contains('overloaded') || lower.contains('503')) {
      return 'Os servidores da IA estão sobrecarregados no momento. '
          'Tente novamente em alguns segundos.';
    }
    if (msg.contains('quota') || msg.contains('429')) {
      return 'Limite de requisições atingido. Tente novamente em instantes.';
    }
    if (msg.contains('network') || msg.contains('SocketException')) {
      return 'Sem conexão com a internet';
    }
    return 'Erro ao gerar resposta: $msg';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildContexto(),
          if (_carregando) const LinearProgressIndicator(),
          Expanded(child: _temConteudo ? _buildConversa() : _buildVazio()),
          _buildCampoPrompt(),
        ],
      ),
    );
  }

  Widget _buildContexto() {
    return StreamBuilder<List<Personagem>>(
      stream: _personagensStream,
      builder: (context, snapshot) {
        _personagens = snapshot.data ?? _personagens;
        final valor = _personagens.any((p) => p.id == _contextoId) ? _contextoId : null;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: DropdownButton<String?>(
            isExpanded: true,
            value: valor,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Pergunta geral (sem personagem)'),
              ),
              for (final p in _personagens)
                DropdownMenuItem<String?>(
                  value: p.id,
                  child: Text('Sobre: ${p.nome}'),
                ),
            ],
            onChanged: _carregando ? null : (v) => setState(() => _contextoId = v),
          ),
        );
      },
    );
  }

  Widget _buildVazio() {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text('Pergunte sobre regras, classes e escolhas',
                style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final s in _sugestoes)
                  ActionChip(label: Text(s), onPressed: () => _enviar(s)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversa() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(_ultimoPrompt),
          ),
        ),
        const SizedBox(height: 16),
        if (_erro != null)
          Card(
            color: theme.colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _erro!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_resposta.isEmpty && _carregando)
                    const Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Pensando...'),
                      ],
                    )
                  else
                    SelectableText(_resposta),
                  if (!_carregando && _resposta.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copiar'),
                        onPressed: _copiar,
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCampoPrompt() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !_carregando,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _enviar(),
                decoration: InputDecoration(
                  hintText: 'Escreva sua pergunta...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _carregando
                ? IconButton.filledTonal(
                    tooltip: 'Parar',
                    icon: const Icon(Icons.stop),
                    onPressed: _parar,
                  )
                : IconButton.filled(
                    tooltip: 'Enviar',
                    icon: const Icon(Icons.send),
                    onPressed: () => _enviar(),
                  ),
          ],
        ),
      ),
    );
  }
}
