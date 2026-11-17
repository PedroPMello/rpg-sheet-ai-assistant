import 'package:cloud_firestore/cloud_firestore.dart';

/// Registro de uma pergunta/resposta do Gemini guardado no Firestore.
class InteracaoIa {
  String id;
  String pergunta;
  String resposta;
  String origem; // assistente | criacao | revisao
  String? personagemId;
  String? personagemNome;
  DateTime? criadoEm;

  InteracaoIa({
    required this.id,
    required this.pergunta,
    required this.resposta,
    required this.origem,
    this.personagemId,
    this.personagemNome,
    this.criadoEm,
  });

  factory InteracaoIa.fromSnap(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data() ?? {};
    final ts = d['criadoEm'];
    return InteracaoIa(
      id: snap.id,
      pergunta: d['pergunta'] ?? '',
      resposta: d['resposta'] ?? '',
      origem: d['origem'] ?? 'assistente',
      personagemId: d['personagemId'],
      personagemNome: d['personagemNome'],
      criadoEm: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String get data {
    final d = criadoEm;
    if (d == null) return 'agora';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}';
  }
}
