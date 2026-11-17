import 'dart:math';

/// Regras básicas de D&D 5e usadas pelo app (cálculos e constantes).
class DndRegras {
  DndRegras._();

  static const List<String> chavesAtributos = [
    'for', 'des', 'con', 'int', 'sab', 'car'
  ];

  static const Map<String, String> siglas = {
    'for': 'FOR', 'des': 'DES', 'con': 'CON',
    'int': 'INT', 'sab': 'SAB', 'car': 'CAR',
  };

  static const Map<String, String> nomes = {
    'for': 'Força', 'des': 'Destreza', 'con': 'Constituição',
    'int': 'Inteligência', 'sab': 'Sabedoria', 'car': 'Carisma',
  };

  /// Índices da API (inglês) -> chaves usadas no app.
  static const Map<String, String> apiParaChave = {
    'str': 'for', 'dex': 'des', 'con': 'con',
    'int': 'int', 'wis': 'sab', 'cha': 'car',
  };

  /// Perícia -> atributo-base.
  static const Map<String, String> pericias = {
    'Acrobacia': 'des',
    'Adestrar Animais': 'sab',
    'Arcanismo': 'int',
    'Atletismo': 'for',
    'Atuação': 'car',
    'Enganação': 'car',
    'Furtividade': 'des',
    'História': 'int',
    'Intimidação': 'car',
    'Intuição': 'sab',
    'Investigação': 'int',
    'Medicina': 'sab',
    'Natureza': 'int',
    'Percepção': 'sab',
    'Persuasão': 'car',
    'Prestidigitação': 'des',
    'Religião': 'int',
    'Sobrevivência': 'sab',
  };

  /// Modificador = (valor - 10) / 2, arredondado para baixo.
  static int modificador(int valor) => ((valor - 10) / 2).floor();

  /// Bônus de proficiência: +2 no nível 1, +1 a cada 4 níveis.
  static int bonusProficiencia(int nivel) => 2 + ((nivel - 1) ~/ 4);

  static String formatarMod(int m) => m >= 0 ? '+$m' : '$m';

  /// Rola 4d6 e descarta o menor dado.
  static int rolar4d6() {
    final r = Random();
    final d = List.generate(4, (_) => r.nextInt(6) + 1)..sort();
    return d[1] + d[2] + d[3];
  }

  /// PV: nível 1 = dado de vida máximo + mod. CON;
  /// níveis seguintes = média do dado (dado/2 + 1) + mod. CON.
  static int calcularPv({
    required int dadoVida,
    required int nivel,
    required int modCon,
  }) {
    final pv = (dadoVida + modCon) + (nivel - 1) * ((dadoVida ~/ 2) + 1 + modCon);
    return pv < nivel ? nivel : pv;
  }
}
