class CardSymbol {
  final String id;
  final String name;
  final String image;
  final String description;

  /// Tres datos curiosos sobre el símbolo. La IA elige uno al azar
  /// para contárselo al jugador cuando encuentra el par.
  final List<String> facts;

  /// Es true cuando la carta es un departamento y no un símbolo patrio.
  final bool isDepartment;

  const CardSymbol({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.facts,
    this.isDepartment = false,
  });
}

/// Rutas de las imágenes de los símbolos patrios.
class CardAssets {
  static const String basePath = 'lib/simbolos patrios';

  /// Imagen que se usa en la parte de atrás de TODAS las cartas.
  static const String back = '$basePath/reverso_carta.jpg';
}

class HonduranSymbols {
  static const List<CardSymbol> all = [
    CardSymbol(
      id: 'escudo',
      name: 'Escudo',
      image: '${CardAssets.basePath}/escudo.jpg',
      description: 'Escudo Nacional',
      facts: [
        'El Escudo Nacional fue creado en 1825 y muestra dos océanos, un volcán, un arcoíris y un sol.',
        'Lleva la frase "República de Honduras, Libre, Soberana e Independiente".',
        'En su parte superior aparece un gorro frigio, símbolo de la libertad.',
      ],
    ),
    CardSymbol(
      id: 'bandera',
      name: 'Bandera',
      image: '${CardAssets.basePath}/bandera.jpg',
      description: 'Pabellón Nacional',
      facts: [
        'El azul de la bandera representa los dos océanos que rodean a Honduras: el Atlántico y el Pacífico.',
        'El blanco simboliza la paz, y las 5 estrellas representan las provincias de Centroamérica.',
        'En 2022 el tono de la franja azul cambió al azul cielo turquesa.',
      ],
    ),
    CardSymbol(
      id: 'flor',
      name: 'Orquídea',
      image: '${CardAssets.basePath}/flor.jpg',
      description: 'Flor Nacional',
      facts: [
        'La flor nacional es la orquídea Rhyncholaelia digbyana, declarada símbolo nacional en 1969.',
        'Su perfume es más intenso al atardecer y durante la noche.',
        'Es una de las orquídeas más grandes y llamativas de Honduras.',
      ],
    ),
    CardSymbol(
      id: 'venado',
      name: 'Venado',
      image: '${CardAssets.basePath}/venado.jpg',
      description: 'Mamífero Nacional',
      facts: [
        'El venado de cola blanca es el mamífero nacional de Honduras desde 1993.',
        'Levanta su cola blanca al correr para avisar a los demás de un peligro.',
        'Habita bosques y llanuras de casi todo el país.',
      ],
    ),
    CardSymbol(
      id: 'cafe',
      name: 'Café',
      image: '${CardAssets.basePath}/cafe.jpg',
      description: 'Producto Nacional',
      facts: [
        'Honduras es uno de los mayores productores de café de Centroamérica.',
        'El café es uno de los principales productos de exportación del país.',
        'Se cultiva en las montañas de Copán, Marcala y la zona occidental.',
      ],
    ),
    CardSymbol(
      id: 'cuestionario',
      name: 'Cuestionario Cívico',
      image: '${CardAssets.basePath}/cuestionario.jpg',
      description: 'Cuestionario Cívico',
      facts: [
        'El Cuestionario Cívico reúne los conocimientos básicos sobre los símbolos y deberes de Honduras.',
        'Enseña fechas patrias como el 15 de septiembre, Día de la Independencia (1821).',
        'Ayuda a los estudiantes a conocer y respetar los símbolos nacionales.',
      ],
    ),
    CardSymbol(
      id: 'guacamaya',
      name: 'Guacamaya',
      image: '${CardAssets.basePath}/guacamaya.jpg',
      description: 'Ave Nacional',
      facts: [
        'La guacamaya roja o "guara" es el ave nacional de Honduras desde 1993.',
        'Puede vivir más de 50 años y suele formar pareja de por vida.',
        'Habita las selvas del norte, como La Mosquitia y el Parque Nacional Cusuco.',
      ],
    ),
    CardSymbol(
      id: 'banano',
      name: 'Banano',
      image: '${CardAssets.basePath}/banano.jpg',
      description: 'Fruto Tropical',
      facts: [
        'El banano es uno de los principales productos de exportación de Honduras.',
        'Su cultivo impulsó el desarrollo económico del país durante el siglo XX.',
        'Se produce sobre todo en el litoral del Caribe, en la zona del Valle de Sula.',
      ],
    ),
    CardSymbol(
      id: 'mapa',
      name: 'Mapa',
      image: '${CardAssets.basePath}/mapa.jpg',
      description: 'Mapa de Honduras',
      facts: [
        'Honduras está en el centro de Centroamérica y limita con Guatemala, El Salvador y Nicaragua.',
        'Tiene costas en dos océanos: el Atlántico (mar Caribe) y el Pacífico.',
        'Su punto más alto es el Cerro Las Minas, con unos 2,870 metros.',
      ],
    ),
    CardSymbol(
      id: 'cacique_lempira',
      name: 'Cacique Lempira',
      image: '${CardAssets.basePath}/cacique lempira.jpg',
      description: 'Héroe Nacional',
      facts: [
        'Lempira fue un líder indígena lenca que luchó contra los españoles entre 1537 y 1538.',
        'Su nombre significa "Señor de la Sierra".',
        'Es el héroe nacional de Honduras y da nombre a la moneda del país.',
      ],
    ),
    CardSymbol(
      id: 'francisco_morazan',
      name: 'Francisco Morazán',
      image: '${CardAssets.basePath}/francisco morazan.jpg',
      description: 'Prócer Nacional',
      facts: [
        'Francisco Morazán nació en Tegucigalpa en 1792.',
        'Fue presidente de la República Federal de Centro América.',
        'Impulsó la unión de los países centroamericanos y grandes reformas liberales.',
      ],
    ),
    CardSymbol(
      id: 'jose_trinidad_cabanas',
      name: 'José Trinidad Cabañas',
      image: '${CardAssets.basePath}/jose trinidad cabañas.jpg',
      description: 'Prócer Nacional',
      facts: [
        'José Trinidad Cabañas fue presidente de Honduras entre 1852 y 1855.',
        'Se destacó como militar y estadista de gran honradez.',
        'Es recordado como ejemplo de servicio y honestidad para el país.',
      ],
    ),
    CardSymbol(
      id: 'lempira',
      name: 'Lempira',
      image: '${CardAssets.basePath}/lempira.jpg',
      description: 'Moneda Nacional',
      facts: [
        'El lempira es la moneda de Honduras y se divide en 100 centavos.',
        'Fue creada en 1931 y lleva el nombre del cacique Lempira.',
        'Su símbolo es la letra "L" y sus billetes muestran próceres y paisajes del país.',
      ],
    ),
  ];

  static List<CardSymbol> getForLevel(int level) {
    switch (level) {
      case 1:
        return all.sublist(0, 4);
      case 2:
        return all.sublist(0, 8);
      case 3:
        return List<CardSymbol>.from(all);
      default:
        return all.sublist(0, 4);
    }
  }
}


/// Modos de juego: los símbolos patrios y los departamentos de Honduras.
enum GameMode { simbolos, departamentos }

/// Los 18 departamentos de Honduras. Cada nivel usa una selección al azar.
class HonduranDepartments {
  static CardSymbol _d(
    String id,
    String name,
    String cabecera,
    List<String> facts,
  ) {
    return CardSymbol(
      id: id,
      name: name,
      image: '${CardAssets.basePath}/dep_$id.png',
      description: 'Cabecera: $cabecera',
      facts: facts,
      isDepartment: true,
    );
  }

  static final List<CardSymbol> all = [
    _d(
      'atlantida',
      'Atlántida',
      'La Ceiba',
      [
        'Su cabecera, La Ceiba, es famosa por su Carnaval Internacional que se celebra cada mes de mayo.',
        'Tiene costa en el mar Caribe y en su territorio está el Parque Nacional Pico Bonito.',
        'Desde La Ceiba salen los barcos hacia las Islas de la Bahía, en especial a Roatán y Utila.',
      ],
    ),
    _d(
      'choluteca',
      'Choluteca',
      'Choluteca',
      [
        'Está en el sur de Honduras y tiene costa en el océano Pacífico, en el golfo de Fonseca.',
        'Su cabecera lleva el mismo nombre y está a orillas del río Choluteca.',
        'En esta zona se cultivan melón y sandía, y se cría camarón para exportar.',
      ],
    ),
    _d(
      'colon',
      'Colón',
      'Trujillo',
      [
        'Cristóbal Colón llegó a esta costa en 1502, en su cuarto viaje, y de él toma su nombre el departamento.',
        'Trujillo, su cabecera, fue una de las primeras ciudades fundadas en Honduras.',
        'Aquí viven comunidades garífunas que mantienen su música, su idioma y su comida.',
      ],
    ),
    _d(
      'comayagua',
      'Comayagua',
      'Comayagua',
      [
        'Fue la capital de Honduras hasta 1880, cuando la capital pasó a Tegucigalpa.',
        'Su catedral tiene un reloj de origen árabe, considerado uno de los más antiguos de América.',
        'Es muy conocida por sus alfombras de aserrín de Semana Santa.',
      ],
    ),
    _d(
      'copan',
      'Copán',
      'Santa Rosa de Copán',
      [
        'Aquí están las ruinas mayas de Copán, declaradas Patrimonio Mundial por la UNESCO en 1980.',
        'Santa Rosa de Copán es famosa por sus puros y su tradición del tabaco.',
        'Limita con Guatemala, en el occidente del país.',
      ],
    ),
    _d(
      'cortes',
      'Cortés',
      'San Pedro Sula',
      [
        'San Pedro Sula, su cabecera, es considerada la capital industrial de Honduras.',
        'Puerto Cortés es el principal puerto del país.',
        'Aquí está la Fortaleza de San Fernando de Omoa, una construcción colonial española.',
      ],
    ),
    _d(
      'el_paraiso',
      'El Paraíso',
      'Yuscarán',
      [
        'Yuscarán, su cabecera, es un pueblo colonial que nació de la minería.',
        'Danlí, en este departamento, celebra cada año el Festival del Maíz.',
        'Limita con Nicaragua, en el oriente del país.',
      ],
    ),
    _d(
      'francisco_morazan',
      'Francisco Morazán',
      'Tegucigalpa',
      [
        'Tegucigalpa es la capital de Honduras desde 1880.',
        'Lleva el nombre del prócer Francisco Morazán, que nació en Tegucigalpa.',
        'Aquí está el Parque Nacional La Tigra, un bosque nublado cerca de la capital.',
      ],
    ),
    _d(
      'gracias_a_dios',
      'Gracias a Dios',
      'Puerto Lempira',
      [
        'Es el departamento de La Mosquitia, una de las zonas más selváticas de Centroamérica.',
        'Aquí está la Reserva de la Biosfera del Río Plátano, Patrimonio Mundial de la UNESCO.',
        'En esta región vive el pueblo miskito, entre otros pueblos.',
      ],
    ),
    _d(
      'intibuca',
      'Intibucá',
      'La Esperanza',
      [
        'La Esperanza, su cabecera, es una de las ciudades más frías del país.',
        'Es una zona con fuerte presencia del pueblo lenca.',
        'Su clima fresco permite cultivar papa y hortalizas.',
      ],
    ),
    _d(
      'islas_de_la_bahia',
      'Islas de la Bahía',
      'Roatán',
      [
        'Está formado por las islas de Roatán, Utila y Guanaja, entre otras.',
        'Cerca de sus costas está el Sistema Arrecifal Mesoamericano, una de las barreras de coral más grandes del mundo.',
        'Es muy visitado para bucear, y en las islas se habla español e inglés.',
      ],
    ),
    _d(
      'la_paz',
      'La Paz',
      'La Paz',
      [
        'Marcala, en este departamento, produce un café con denominación de origen.',
        'Es un departamento de montañas y clima fresco.',
        'Su café se cultiva en las montañas, a buena altura sobre el nivel del mar.',
      ],
    ),
    _d(
      'lempira',
      'Lempira',
      'Gracias',
      [
        'Lleva el nombre del cacique Lempira, héroe nacional de Honduras.',
        'La ciudad de Gracias fue sede de la Real Audiencia de los Confines en 1544.',
        'Aquí está el Parque Nacional Montaña de Celaque, donde se encuentra el Cerro Las Minas, el punto más alto de Honduras.',
      ],
    ),
    _d(
      'ocotepeque',
      'Ocotepeque',
      'Nueva Ocotepeque',
      [
        'Limita con Guatemala y El Salvador, en el occidente del país.',
        'Cerca está la Reserva Trifinio, donde se juntan las fronteras de tres países.',
        'Tiene clima fresco y es zona de producción de café.',
      ],
    ),
    _d(
      'olancho',
      'Olancho',
      'Juticalpa',
      [
        'Es el departamento más grande de Honduras.',
        'Es famoso por su ganadería, sus bosques y su producción de madera.',
        'Aquí está el Parque Nacional Sierra de Agalta.',
      ],
    ),
    _d(
      'santa_barbara',
      'Santa Bárbara',
      'Santa Bárbara',
      [
        'Parte del Lago de Yojoa está en este departamento.',
        'Es conocido por sus artesanías hechas con junco.',
        'En sus montañas se cultiva buena parte del café del occidente del país.',
      ],
    ),
    _d(
      'valle',
      'Valle',
      'Nacaome',
      [
        'Tiene costa en el golfo de Fonseca, en el océano Pacífico.',
        'En el golfo está la Isla del Tigre, con el puerto de Amapala.',
        'San Lorenzo es uno de sus puertos sobre el Pacífico.',
      ],
    ),
    _d(
      'yoro',
      'Yoro',
      'Yoro',
      [
        'Aquí ocurre el fenómeno de la lluvia de peces, que se celebra con una feria.',
        'Es uno de los departamentos más extensos del norte del país.',
        'Es un departamento de valles y montañas en el norte de Honduras.',
      ],
    ),
  ];

  /// Elige al azar tantos departamentos como pares tenga el nivel.
  static List<CardSymbol> randomForLevel(int level) {
    final pairs = LevelConfig.get(level).pairs;
    final list = List<CardSymbol>.from(all)..shuffle();
    return list.take(pairs).toList();
  }
}

class LevelConfig {
  final int level;
  final String name;
  final String description;
  final int pairs;
  final int timeSeconds;

  const LevelConfig({
    required this.level,
    required this.name,
    required this.description,
    required this.pairs,
    required this.timeSeconds,
  });

  static const List<LevelConfig> levels = [
    LevelConfig(
      level: 1,
      name: 'Fácil',
      description: '4 pares de cartas',
      pairs: 4,
      timeSeconds: 60,
    ),
    LevelConfig(
      level: 2,
      name: 'Intermedio',
      description: '8 pares de cartas',
      pairs: 8,
      timeSeconds: 60,
    ),
    LevelConfig(
      level: 3,
      name: 'Difícil',
      description: '13 pares de cartas',
      pairs: 13,
      timeSeconds: 60,
    ),
  ];

  static LevelConfig get(int level) {
    return levels.firstWhere(
      (l) => l.level == level,
      orElse: () => levels.first,
    );
  }
}
