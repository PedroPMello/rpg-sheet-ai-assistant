import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/interacao_ia.dart';

/// Histórico de perguntas/respostas do Gemini em users/{uid}/historico_ia.
class HistoricoIaService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('historico_ia');
  }

  Future<void> salvar({
    required String pergunta,
    required String resposta,
    required String origem,
    String? personagemId,
    String? personagemNome,
  }) =>
      _col.add({
        'pergunta': pergunta,
        'resposta': resposta,
        'origem': origem,
        'personagemId': personagemId,
        'personagemNome': personagemNome,
        'criadoEm': FieldValue.serverTimestamp(),
      });

  Stream<List<InteracaoIa>> listar() =>
      _col.orderBy('criadoEm', descending: true).snapshots().map(
            (s) => s.docs.map((d) => InteracaoIa.fromSnap(d)).toList(),
          );

  Future<void> excluir(String id) => _col.doc(id).delete();
}
