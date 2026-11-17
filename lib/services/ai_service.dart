import 'package:firebase_ai/firebase_ai.dart';
import '../core/ai_config.dart';

//Camada que conversa com o Firebase AI Logic.
//A interface nunca chama o SDK diretamente, só este serviço.
class AiService {
  AiService() {
    final ai = FirebaseAI.googleAI();
    _modelos = [
      for(final nome in AiConfig.modelos)
        ai.generativeModel(
            model: nome,
            systemInstruction: Content.system(AiConfig.systemInstruction),
        )
    ];
  }

  late final List<GenerativeModel> _modelos;

  ///Resposta em pedaços (streaming), com nova tentativa e troca de modelo
///quando o servidor está sobrecarregado.
Stream<String> gerarEmStream(String prompt) async* {
  Object? ultimoErro;

  for (final model in _modelos) {
    for(var tentativa = 1;
    tentativa <= AiConfig.tentativasPorModelo;
    tentativa++) {
      var recebeuAlgo = false;
      try {
        final stream = model.generateContentStream([Content.text(prompt)]);
        await for (final chunk in stream) {
          final texto = chunk.text;
          if (texto != null && texto.isNotEmpty) {
            recebeuAlgo = true;
            yield texto;
          }
        }
        return;
      } catch (e) {
        if (recebeuAlgo || !_ehTemporario(e)) rethrow;
        ultimoErro = e;
        //  Espera um pouco antes de tentar de novo: 1s, 2s...
        await Future.delayed(Duration(seconds: tentativa));
      }
    }
  }
  throw ultimoErro ?? Exception('Não foi possível gerar a resposta.');
}

bool _ehTemporario(Object e) {
  final msg = e.toString().toLowerCase();
  return msg.contains('high demand') ||
      msg.contains('overloaded') ||
      msg.contains('unavailable') ||
      msg.contains('503') ||
      msg.contains('429') ||
      msg.contains('resource exhausted');
}

}