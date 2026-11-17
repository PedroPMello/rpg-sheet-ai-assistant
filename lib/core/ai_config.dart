class AiConfig {
  AiConfig._();

  static const List<String> modelos = [
    'gemini-3.5-flash-lite', //mais rápido
    'gemini-3.1-flash-lite',
    'gemini-3.5-flash'
  ];

  static const int tentativasPorModelo = 2;

  ///Instrução de sistema: define o "comportamento" do assistente
  static const String systemInstruction =
      'Você é um assistente especialista em Dungeons & Dragons 5ª edição '
      '(regras do SRD). Ajude jogadores iniciantes a criar personagens, '
      'escolher raça, classe, atributos, perícias e equipamento, e a '
      'entender as regras do sistema. Responda sempre em Português do '
      'Brasil, de forma clara, objetiva e didática, citando o nome original '
      'em inglês entre parênteses quando isso ajudar. Se não tiver certeza '
      'de uma regra, diga isso. Se a pergunta não for sobre RPG, responda '
      'brevemente e traga a conversa de volta ao jogo.';

  ///Chave do site reCAPTCHA v3 (só usada no Flutter Web)
  ///Crie em https://www.google.com/recaptcha/admin e registre no
  ///Firebase Console > App Check > Apps > (app web)
  static const String recaptchaSiteKey = 'COLOQUE_SUA_CHAVE_RECAPTCHA_AQUI';
}
