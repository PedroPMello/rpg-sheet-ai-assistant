import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/personagem.dart';

/// CRUD dos personagens em users/{uid}/personagens.
class PersonagemService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _col {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('personagens');
  }

  // CREATE
  Future<void> criar(Personagem p) => _col.add({
        ...p.toMap(),
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

  // READ (lista em tempo real)
  Stream<List<Personagem>> listar() => _col.orderBy('nome').snapshots().map(
        (s) => s.docs.map((d) => Personagem.fromSnap(d)).toList(),
      );

  // READ (um personagem em tempo real)
  Stream<Personagem?> observar(String id) => _col
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Personagem.fromSnap(s) : null);

  // UPDATE (ficha completa)
  Future<void> atualizar(Personagem p) => _col.doc(p.id).update({
        ...p.toMap(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

  // UPDATE (só os PV, usado nos botões +/-)
  Future<void> atualizarPv(String id, int pv) =>
      _col.doc(id).update({'pvAtual': pv});

  // DELETE
  Future<void> excluir(String id) => _col.doc(id).delete();
}
