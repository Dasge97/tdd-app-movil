/**
 * Prompt 1 — Search
 * Instructs the AI to find 10-12 relevant, debatable news items for today.
 *
 * @param {Array<{ title: string, dayDate: string }>} recentTopics
 * @returns {string}
 */
export function buildSearchPrompt(recentTopics) {
  const today = new Date().toLocaleDateString('es-ES', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

  const recentList =
    recentTopics.length > 0
      ? recentTopics.map((t) => `- ${t.title} (${t.dayDate})`).join('\n')
      : '(No hay publicaciones recientes registradas)';

  return `Eres un editor periodístico experto en curación de contenido. Hoy es ${today}.

TEMAS YA PUBLICADOS en los últimos 14 días (evita repetirlos o temas demasiado similares):
${recentList}

Tu tarea: Busca y lista entre 10 y 12 noticias relevantes de HOY, con foco principal en España. Elige noticias de temáticas variadas: política, economía, ciencia, sociedad, tecnología, medioambiente, ética, filosofía aplicada.

Para cada noticia proporciona:
1. Titular (conciso y fiel al hecho)
2. Fuente y URL verificable
3. 1-2 frases de contexto (qué ocurrió, quiénes están implicados)
4. Por qué es debatible: qué posturas enfrentadas genera, qué dilema ético o social plantea

Criterios de selección:
- Noticias de las últimas 48 horas
- Evita clickbait, noticias de entretenimiento puro o deportes
- Evita temas idénticos o muy similares a los ya publicados arriba
- Prioriza noticias que generen debate genuino con al menos dos posturas legítimas
- España primero: al menos 7 u 8 noticias deben ser de actualidad española (política nacional, sociedad, economía, ciencia o medioambiente en España)
- Solo incluye noticias internacionales si el tema tiene un impacto global inequívoco y transversal (crisis geopolítica grave, pandemia, descubrimiento científico de alcance mundial, etc.); evita noticias extranjeras de interés local o regional

Formatea la lista numerada del 1 al 12.`;
}
