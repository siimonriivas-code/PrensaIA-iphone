// Demo data for the PrensaIA prototype — a realistic Colima press interview.
// Speakers: 0 = Reportera (PrensaIA), 1 = Indira Vizcaíno (gobernadora), 2 = Vocero CIAPACOV

const DEMO_SEGMENTS = [
  { start: 0,   end: 9,   speakerId: 0, text: "Gobernadora, ¿en qué consiste la rehabilitación del pozo profundo \u201cCuajiote\u201d que entrega hoy?" },
  { start: 9,   end: 27,  speakerId: 1, text: "Es una inversión histórica de 5.3 millones de pesos para rehabilitar y equipar por completo el pozo. Con esto garantizamos agua a más de 40 mil familias del oriente de Colima." },
  { start: 27,  end: 41,  speakerId: 1, text: "Veníamos arrastrando un rezago de años en infraestructura hidráulica. Hoy cambiamos esa historia con obra concreta, no con promesas." },
  { start: 41,  end: 52,  speakerId: 0, text: "¿Cómo se financió la obra y en cuánto tiempo se ejecutó?" },
  { start: 52,  end: 70,  speakerId: 1, text: "Fue recurso estatal en coordinación con el municipio. La obra se ejecutó en cuatro meses, sin sobrecostos y con mano de obra local, que es algo que para nosotros es fundamental." },
  { start: 70,  end: 86,  speakerId: 2, text: "Técnicamente se renovó el equipo de bombeo, la línea de conducción y el sistema eléctrico. El pozo pasa de 18 a 42 litros por segundo, más del doble de capacidad." },
  { start: 86,  end: 99,  speakerId: 0, text: "¿Qué sigue en el plan hídrico para el resto del estado?" },
  { start: 99,  end: 118, speakerId: 1, text: "Vamos a cuadruplicar la meta de rehabilitación: de cinco pozos pasamos a veinte en los próximos dos años. El agua no puede seguir siendo un privilegio en Colima, tiene que ser un derecho que se cumple." },
  { start: 118, end: 131, speakerId: 0, text: "Sobre el tema político, ¿le preocupa el panorama rumbo a 2027?" },
  { start: 131, end: 148, speakerId: 1, text: "Yo estoy concentrada en gobernar y en entregar resultados. Las elecciones llegarán a su tiempo; mientras tanto, mi responsabilidad es que cada familia abra la llave y tenga agua." },
];

const SPEAKER_NAMES = { 0: "Reportera", 1: "Indira Vizcaíno", 2: "Vocero CIAPACOV" };

const DEMO_ANALYSIS = {
  resumen: "La gobernadora Indira Vizcaíno entregó la rehabilitación del pozo profundo \u201cCuajiote\u201d, una inversión de 5.3 mdp que beneficia a más de 40 mil familias del oriente de Colima. Anunció que cuadruplicará la meta estatal de rehabilitación de pozos, de cinco a veinte en dos años.",
  temas: [
    "Inversión hídrica de 5.3 mdp en el pozo \u201cCuajiote\u201d",
    "Cobertura para más de 40 mil familias",
    "Meta estatal: de 5 a 20 pozos en dos años",
    "Postura ante el panorama electoral 2027",
  ],
  frasesDestacadas: [
    "El agua no puede seguir siendo un privilegio en Colima, tiene que ser un derecho que se cumple.",
    "Hoy cambiamos esa historia con obra concreta, no con promesas.",
    "Vamos a cuadruplicar la meta de rehabilitación: de cinco pozos pasamos a veinte.",
  ],
  titulares: [
    "Indira Vizcaíno cuadruplica la meta de pozos rehabilitados en Colima",
    "Inversión histórica de 5.3 mdp lleva agua a 40 mil familias del oriente",
    "\u201cEl agua tiene que ser un derecho\u201d: Vizcaíno entrega el pozo Cuajiote",
  ],
};

const DEMO_CORTES = [
  { tema: "Entrega del pozo Cuajiote", inicio: 0,   fin: 41,  resumen: "Detalle de la inversión de 5.3 mdp y el beneficio a 40 mil familias." },
  { tema: "Financiamiento y ejecución", inicio: 41,  fin: 86,  resumen: "Recurso estatal, cuatro meses de obra y duplicación de la capacidad del pozo." },
  { tema: "Plan hídrico estatal", inicio: 86,  fin: 118, resumen: "Anuncio de cuadruplicar la meta: de cinco a veinte pozos en dos años." },
  { tema: "Panorama político 2027", inicio: 118, fin: 148, resumen: "La gobernadora evita adelantar definiciones electorales." },
];

const DEMO_HISTORY = [
  { title: "Indira Vizcaíno entrega el pozo \u201cCuajiote\u201d", date: "Hoy, 9:41", analysis: true },
  { title: "Rosi Bayardo — gira por el puerto de Manzanillo", date: "Ayer, 18:20", analysis: true },
  { title: "Conferencia matutina — seguridad estatal", date: "19 jun, 8:05", analysis: false },
  { title: "Cabildo de Colima — sesión ordinaria", date: "17 jun, 11:32", analysis: true },
  { title: "Entrevista — programa de infraestructura carretera", date: "14 jun, 16:48", analysis: false },
];

const DEMO_DICCIONARIO = [
  { wrong: "Bizcaino", right: "Vizcaíno" },
  { wrong: "Sheimbau", right: "Sheinbaum" },
  { wrong: "Ciapacov", right: "CIAPACOV" },
  { wrong: "Cuajote", right: "Cuajiote" },
];

function fmtTime(seconds) {
  const s = Math.round(seconds);
  const m = Math.floor(s / 60), sec = s % 60;
  return `${String(m).padStart(2, "0")}:${String(sec).padStart(2, "0")}`;
}

Object.assign(window, {
  DEMO_SEGMENTS, SPEAKER_NAMES, DEMO_ANALYSIS, DEMO_CORTES,
  DEMO_HISTORY, DEMO_DICCIONARIO, fmtTime,
});
