import 'package:flutter/material.dart';
import '../components/ajuda_ia_sheet.dart';
import '../components/editor.dart';
import '../core/dnd_regras.dart';
import '../models/personagem.dart';
import '../services/dnd_api_service.dart';
import '../services/personagem_service.dart';

/// Criação e edição de ficha (CREATE / UPDATE).
class PersonagemFormPage extends StatefulWidget {
  final Personagem? personagem; // null = novo
  const PersonagemFormPage({super.key, this.personagem});

  @override
  State<PersonagemFormPage> createState() => _PersonagemFormPageState();
}

class _PersonagemFormPageState extends State<PersonagemFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _api = DndApiService();
  final _service = PersonagemService();

  final _nome = TextEditingController();
  final _antecedente = TextEditingController();
  final _equipamento = TextEditingController();
  final _historia = TextEditingController();
  final _pvMax = TextEditingController(text: '10');
  final _ca = TextEditingController(text: '10');
  final _deslocamento = TextEditingController(text: '30');

  List<ItemApi> _racas = [];
  List<ItemApi> _classes = [];
  List<ItemApi> _alinhamentos = [];
  String? _raca;
  String? _classe;
  String? _alinhamento;
  int _nivel = 1;
  int? _dadoVida;
  String _bonusRacial = '';
  Map<String, int> _atributos = {for (final k in DndRegras.chavesAtributos) k: 10};
  final Set<String> _pericias = {};

  bool _carregandoApi = true;
  String? _erroApi;
  bool _salvando = false;

  bool get _editando => widget.personagem != null;

  @override
  void initState() {
    super.initState();
    final p = widget.personagem;
    if (p != null) {
      _nome.text = p.nome;
      _antecedente.text = p.antecedente;
      _equipamento.text = p.equipamento;
      _historia.text = p.historia;
      _pvMax.text = '${p.pvMax}';
      _ca.text = '${p.ca}';
      _deslocamento.text = '${p.deslocamento}';
      _raca = p.raca.isEmpty ? null : p.raca;
      _classe = p.classe.isEmpty ? null : p.classe;
      _alinhamento = p.alinhamento.isEmpty ? null : p.alinhamento;
      _nivel = p.nivel;
      _atributos = Map.of(p.atributos);
      _pericias.addAll(p.pericias);
    }
    _carregarApi();
  }

  @override
  void dispose() {
    for (final c in [_nome, _antecedente, _equipamento, _historia, _pvMax, _ca, _deslocamento]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarApi() async {
    setState(() {
      _carregandoApi = true;
      _erroApi = null;
    });
    try {
      final r = await Future.wait([
        _api.listar('races'),
        _api.listar('classes'),
        _api.listar('alignments'),
      ]);
      _racas = r[0];
      _classes = r[1];
      _alinhamentos = r[2];
      final c = _classes.where((i) => i.nome == _classe).firstOrNull;
      if (c != null) {
        _dadoVida = (await _api.detalhe('classes', c.index))['hit_die'] as int?;
      }
    } catch (e) {
      _erroApi = 'Não foi possível carregar os dados da API de D&D: $e';
    }
    if (mounted) setState(() => _carregandoApi = false);
  }

  Future<void> _aoMudarRaca(String? nome) async {
    setState(() {
      _raca = nome;
      _bonusRacial = '';
    });
    final item = _racas.where((r) => r.nome == nome).firstOrNull;
    if (item == null) return;
    try {
      final d = await _api.detalhe('races', item.index);
      final bonus = (d['ability_bonuses'] as List? ?? [])
          .map((b) {
            final chave = DndRegras.apiParaChave[b['ability_score']['index']];
            return chave == null ? null : '${DndRegras.siglas[chave]} +${b['bonus']}';
          })
          .whereType<String>()
          .join(', ');
      if (!mounted) return;
      setState(() {
        _bonusRacial = bonus;
        if (d['speed'] != null) _deslocamento.text = '${d['speed']}';
      });
    } catch (_) {
      // Sem os detalhes o usuário ainda pode preencher manualmente.
    }
  }

  Future<void> _aoMudarClasse(String? nome) async {
    setState(() {
      _classe = nome;
      _dadoVida = null;
    });
    final item = _classes.where((c) => c.nome == nome).firstOrNull;
    if (item == null) return;
    try {
      final d = await _api.detalhe('classes', item.index);
      if (mounted) setState(() => _dadoVida = d['hit_die'] as int?);
    } catch (_) {}
  }

  void _calcularPv() {
    if (_dadoVida == null) {
      _aviso('Escolha uma classe primeiro.');
      return;
    }
    final pv = DndRegras.calcularPv(
      dadoVida: _dadoVida!,
      nivel: _nivel,
      modCon: DndRegras.modificador(_atributos['con']!),
    );
    setState(() => _pvMax.text = '$pv');
  }

  Personagem _montar() {
    final pvMax = int.tryParse(_pvMax.text) ?? 1;
    final atual = widget.personagem?.pvAtual ?? pvMax;
    return Personagem(
      id: widget.personagem?.id,
      nome: _nome.text.trim(),
      raca: _raca ?? '',
      classe: _classe ?? '',
      antecedente: _antecedente.text.trim(),
      alinhamento: _alinhamento ?? '',
      nivel: _nivel,
      atributos: Map.of(_atributos),
      pvMax: pvMax,
      pvAtual: atual > pvMax ? pvMax : atual,
      ca: int.tryParse(_ca.text) ?? 10,
      deslocamento: int.tryParse(_deslocamento.text) ?? 30,
      pericias: _pericias.toList()..sort(),
      equipamento: _equipamento.text.trim(),
      historia: _historia.text.trim(),
    );
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _salvando = true);
    try {
      final p = _montar();
      if (_editando) {
        await _service.atualizar(p);
      } else {
        await _service.criar(p);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _aviso('Erro ao salvar: $e');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _pedirIa() {
    final p = _montar();
    final verbo = _editando ? 'revisando' : 'criando';
    pedirAjudaIa(
      context,
      titulo: 'Sugestões da IA',
      pergunta: 'Sugestões para a ficha${p.nome.isEmpty ? "" : " de ${p.nome}"}',
      origem: 'criacao',
      personagemId: p.id,
      personagemNome: p.nome.isEmpty ? null : p.nome,
      prompt: 'Estou $verbo um personagem de D&D 5e. Dados atuais:\n'
          '${p.resumo()}\n\n'
          'Com base nisso: 1) sugira ajustes na distribuição de atributos '
          '(conjunto padrão 15, 14, 13, 12, 10, 8); 2) indique perícias '
          'recomendadas e quantas posso escolher; 3) sugira equipamento '
          'inicial; 4) dê ideias de antecedente e personalidade. Explique '
          'cada escolha em poucas frases, para um iniciante.',
    );
  }

  void _aviso(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  String? _validaInt(String? v, {int min = 0}) {
    final n = int.tryParse(v ?? '');
    return (n == null || n < min) ? 'Número inválido' : null;
  }

  Widget _dropdown({
    required String rotulo,
    required List<ItemApi> itens,
    required String? valor,
    required ValueChanged<String?> onChanged,
    bool obrigatorio = true,
  }) {
    final existe = itens.any((i) => i.nome == valor);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DropdownButtonFormField<String>(
        // ignore: deprecated_member_use
        value: existe ? valor : null,
        isExpanded: true,
        decoration: InputDecoration(labelText: rotulo),
        items: [
          for (final i in itens) DropdownMenuItem(value: i.nome, child: Text(i.nome)),
        ],
        onChanged: onChanged,
        validator: (v) => (obrigatorio && v == null) ? 'Escolha uma opção' : null,
      ),
    );
  }

  Widget _campoNumero(String rotulo, TextEditingController c, {int min = 0}) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: rotulo),
      validator: (v) => _validaInt(v, min: min),
    );
  }

  Widget _linhaAtributo(String k) {
    final valor = _atributos[k]!;
    return Row(
      children: [
        SizedBox(width: 92, child: Text(DndRegras.nomes[k]!)),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: valor > 1 ? () => setState(() => _atributos[k] = valor - 1) : null,
        ),
        SizedBox(
          width: 30,
          child: Text('$valor',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: valor < 30 ? () => setState(() => _atributos[k] = valor + 1) : null,
        ),
        SizedBox(
          width: 36,
          child: Text(DndRegras.formatarMod(DndRegras.modificador(valor))),
        ),
        IconButton(
          tooltip: 'Rolar 4d6 (descarta o menor)',
          icon: const Icon(Icons.casino_outlined),
          onPressed: () => setState(() => _atributos[k] = DndRegras.rolar4d6()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_editando ? 'Editar personagem' : 'Novo personagem')),
      body: _carregandoApi
          ? const Center(child: CircularProgressIndicator())
          : _erroApi != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_erroApi!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _carregarApi,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 32),
                    children: [
                      Editor(_nome, 'Nome do personagem', 'Ex.: Thorin', icone: Icons.person),
                      _dropdown(
                        rotulo: 'Raça',
                        itens: _racas,
                        valor: _raca,
                        onChanged: _aoMudarRaca,
                      ),
                      if (_bonusRacial.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Bônus de atributo da raça: $_bonusRacial (some aos atributos abaixo)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      _dropdown(
                        rotulo: 'Classe',
                        itens: _classes,
                        valor: _classe,
                        onChanged: _aoMudarClasse,
                      ),
                      if (_dadoVida != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Dado de vida da classe: d$_dadoVida',
                              style: theme.textTheme.bodyMedium),
                        ),
                      _dropdown(
                        rotulo: 'Alinhamento',
                        itens: _alinhamentos,
                        valor: _alinhamento,
                        obrigatorio: false,
                        onChanged: (v) => setState(() => _alinhamento = v),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextFormField(
                          controller: _antecedente,
                          decoration: const InputDecoration(
                            labelText: 'Antecedente (ex.: Acólito, Soldado)',
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Text('Nível: $_nivel', style: theme.textTheme.titleMedium),
                      ),
                      Slider(
                        value: _nivel.toDouble(),
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: '$_nivel',
                        onChanged: (v) => setState(() => _nivel = v.round()),
                      ),

                      // Atributos
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Atributos', style: theme.textTheme.titleMedium),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.casino_outlined),
                                  label: const Text('Rolar todos'),
                                  onPressed: () => setState(() {
                                    for (final k in DndRegras.chavesAtributos) {
                                      _atributos[k] = DndRegras.rolar4d6();
                                    }
                                  }),
                                ),
                              ],
                            ),
                            for (final k in DndRegras.chavesAtributos) _linhaAtributo(k),
                          ],
                        ),
                      ),

                      // Combate
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _campoNumero('PV máx.', _pvMax, min: 1)),
                            const SizedBox(width: 8),
                            Expanded(child: _campoNumero('CA', _ca)),
                            const SizedBox(width: 8),
                            Expanded(child: _campoNumero('Desloc. (ft)', _deslocamento)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.favorite_outline),
                            label: const Text('Calcular PV pela classe'),
                            onPressed: _calcularPv,
                          ),
                        ),
                      ),

                      // Perícias
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text('Perícias proficientes', style: theme.textTheme.titleMedium),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            for (final nome in DndRegras.pericias.keys)
                              FilterChip(
                                label: Text(nome),
                                selected: _pericias.contains(nome),
                                onSelected: (sel) => setState(() {
                                  sel ? _pericias.add(nome) : _pericias.remove(nome);
                                }),
                              ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        child: TextFormField(
                          controller: _equipamento,
                          minLines: 2,
                          maxLines: 5,
                          decoration: const InputDecoration(labelText: 'Equipamento'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: TextFormField(
                          controller: _historia,
                          minLines: 3,
                          maxLines: 8,
                          decoration: const InputDecoration(
                            labelText: 'História e personalidade',
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Pedir ajuda à IA'),
                              onPressed: _pedirIa,
                            ),
                            const SizedBox(height: 12),
                            FilledButton.icon(
                              icon: _salvando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save),
                              label: Text(_editando ? 'Salvar alterações' : 'Criar personagem'),
                              onPressed: _salvando ? null : _salvar,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
