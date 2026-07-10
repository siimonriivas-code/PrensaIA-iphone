// PrensaIA v3 — datos extra: onda, onboarding, lectura casi en vivo, QA.

// Onda de audio pseudo-aleatoria pero estable (160 barras, como WaveformLoader).
const WAVE_SAMPLES = (() => {
  const out = [];
  let seed = 7;
  const rnd = () => { seed = (seed * 16807) % 2147483647; return seed / 2147483647; };
  for (let i = 0; i < 160; i++) {
    const voice = 0.25 + 0.75 * Math.abs(Math.sin(i / 7.3)) * (0.55 + 0.45 * rnd());
    const pause = (i % 23 < 2) ? 0.12 : 1;
    out.push(Math.min(1, voice * pause));
  }
  return out;
})();

const ONBOARDING_PAGES = [
  { icon: "waveform", title: "Transcribe sin internet",
    text: "Sube un archivo, graba o captura audio. Todo se procesa dentro de tu iPhone: rápido, privado y sin depender de la señal." },
  { icon: "radio", title: "Facebook Live, sin bocina",
    text: "Captura el audio de una transmisión directamente del teléfono y léela casi en tiempo real. Nadie a tu alrededor escucha nada." },
  { icon: "scissors", title: "Tus temas y tus cortes",
    text: "Marca los momentos importantes con tu nombre de tema, deja que la IA sugiera bloques, y exporta clips de video listos para publicar." },
  { icon: "sparkles", title: "Análisis periodístico",
    text: "Resumen, temas, citas textuales verificadas y titulares sugeridos. Y si tienes dudas, pregúntale directamente a la entrevista." },
];

// Lectura casi en vivo (Facebook Live): llega por tramos de ~20 s.
const FOLLOW_CHUNKS = [
  "Muy buenas tardes a todas y a todos, gracias por acompañarnos en esta transmisión desde el oriente de Colima.",
  "Hoy entregamos la rehabilitación del pozo profundo Cuajiote, una obra esperada por años en esta zona.",
  "Son cinco punto tres millones de pesos de inversión directa que garantizan agua para más de cuarenta mil familias.",
  "La obra se ejecutó en cuatro meses, con mano de obra local y sin sobrecostos, en coordinación con el municipio.",
];

// Respuesta simulada de "Pregúntale a esta entrevista".
const QA_ANSWER = "Sobre 2027, la gobernadora evitó adelantar definiciones: dijo estar concentrada en gobernar y entregar resultados, y que \u201clas elecciones llegarán a su tiempo\u201d. No mencionó aspiraciones ni candidaturas.";

// Versión "limpia" de la estenográfica (sin muletillas, puntuación revisada).
function cleanTurnText(t) {
  return t.replace(/\u2026/g, "").replace(/\s+/g, " ").trim();
}

// Agrupa segmentos consecutivos por orador.
function groupTurns(segments) {
  const turns = [];
  segments.forEach(s => {
    const last = turns[turns.length - 1];
    if (last && last.speakerId === s.speakerId) last.text += " " + s.text;
    else turns.push({ speakerId: s.speakerId, text: s.text });
  });
  return turns;
}

Object.assign(window, {
  WAVE_SAMPLES, ONBOARDING_PAGES, FOLLOW_CHUNKS, QA_ANSWER, cleanTurnText, groupTurns,
});
