import 'dart:convert';
import 'package:http/http.dart' as http;

class ItemApi {
  final String index;
  final String nome;
  const ItemApi({required this.index, required this.nome});
}

/// Consulta a API pública de D&D 5e (https://www.dnd5eapi.co).
class DndApiService {
  static const String _api = 'https://www.dnd5eapi.co/api/2014';

  /// Lista um recurso: 'races', 'classes', 'alignments'...
  Future<List<ItemApi>> listar(String recurso) async {
    final json = await _get('$_api/$recurso');
    return [
      for (final i in json['results'] as List)
        ItemApi(index: i['index'] as String, nome: i['name'] as String),
    ];
  }

  /// Detalhes de um item, ex.: detalhe('classes', 'wizard').
  Future<Map<String, dynamic>> detalhe(String recurso, String index) =>
      _get('$_api/$recurso/$index');

  Future<Map<String, dynamic>> _get(String url) async {
    final r = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) {
      throw Exception('A API de D&D respondeu ${r.statusCode}');
    }
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  }
}
