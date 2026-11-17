import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/dnd_regras.dart';

class Personagem {
  String? id;
  String nome;
  String raca;
  String classe;
  String antecedente;
  String alinhamento;
  int nivel;
  Map<String, int> atributos;
  int pvMax;
  int pvAtual;
  int ca;
  int deslocamento;
  List<String> pericias;
  String equipamento;
  String historia;

  Personagem({
    this.id,
    required this.nome,
    required this.raca,
    required this.classe,
    this.antecedente = '',
    this.alinhamento = '',
    this.nivel = 1,
    required this.atributos,
    this.pvMax = 10,
    this.pvAtual = 10,
    this.ca = 10,
    this.deslocamento = 30,
    this.pericias = const [],
    this.equipamento = '',
    this.historia = '',
  });

  int mod(String chave) => DndRegras.modificador(atributos[chave] ?? 10);

  int get bonusProficiencia => DndRegras.bonusProficiencia(nivel);

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'raca': raca,
        'classe': classe,
        'antecedente': antecedente,
        'alinhamento': alinhamento,
        'nivel': nivel,
        'atributos': atributos,
        'pvMax': pvMax,
        'pvAtual': pvAtual,
        'ca': ca,
        'deslocamento': deslocamento,
        'pericias': pericias,
        'equipamento': equipamento,
        'historia': historia,
      };

  factory Personagem.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final at = (d['atributos'] as Map?) ?? {};
    return Personagem(
      id: snap.id,
      nome: d['nome'] ?? '',
      raca: d['raca'] ?? '',
      classe: d['classe'] ?? '',
      antecedente: d['antecedente'] ?? '',
      alinhamento: d['alinhamento'] ?? '',
      nivel: (d['nivel'] ?? 1) as int,
      atributos: {
        for (final k in DndRegras.chavesAtributos) k: (at[k] ?? 10) as int,
      },
      pvMax: (d['pvMax'] ?? 1) as int,
      pvAtual: (d['pvAtual'] ?? 1) as int,
      ca: (d['ca'] ?? 10) as int,
      deslocamento: (d['deslocamento'] ?? 30) as int,
      pericias: List<String>.from(d['pericias'] ?? const []),
      equipamento: d['equipamento'] ?? '',
      historia: d['historia'] ?? '',
    );
  }

  /// Texto enviado ao Gemini como contexto do personagem.
  String resumo() {
    final attrs = DndRegras.chavesAtributos
        .map((k) => '${DndRegras.siglas[k]} ${atributos[k]} '
            '(${DndRegras.formatarMod(mod(k))})')
        .join(', ');
    return 'Nome: ${nome.isEmpty ? "(sem nome)" : nome}\n'
        'Raça: ${raca.isEmpty ? "(não escolhida)" : raca}\n'
        'Classe: ${classe.isEmpty ? "(não escolhida)" : classe}\n'
        'Nível: $nivel\n'
        'Antecedente: ${antecedente.isEmpty ? "(não definido)" : antecedente}\n'
        'Alinhamento: ${alinhamento.isEmpty ? "(não definido)" : alinhamento}\n'
        'Atributos: $attrs\n'
        'PV: $pvMax | CA: $ca | Deslocamento: $deslocamento ft\n'
        'Perícias proficientes: ${pericias.isEmpty ? "(nenhuma)" : pericias.join(", ")}\n'
        'Equipamento: ${equipamento.isEmpty ? "(nenhum)" : equipamento}';
  }
}
