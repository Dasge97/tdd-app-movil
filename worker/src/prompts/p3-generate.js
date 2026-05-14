/**
 * Prompt 3 — Generation
 * Instructs the AI to produce the full debate content for each assigned pair.
 *
 * @param {Array<{ persona: Object, noticia: Object }>} assignedPersonas
 * @returns {string}
 */
export function buildGenerationPrompt(assignedPersonas) {
  const profileSections = assignedPersonas.map(({ persona, noticia }) => `
## @${persona.username} — ${persona.bio}
Tagline: "${persona.tagline}"
Rasgos de voz: ${persona.traits.join(', ')}
Noticia asignada: "${noticia.titulo}"
Fuente: ${noticia.fuente}
URL: ${noticia.url}
Contexto de la noticia: ${noticia.contexto || 'Ver noticia completa en la URL indicada.'}
`).join('\n');

  return `Usando los 5 pares noticia-perfil que seleccionaste, genera el contenido completo de cada debate.

REGLAS DE CALIDAD (obligatorias):

title:
- Pregunta directa sobre el dilema central de la noticia
- Entre 60 y 120 caracteres
- Debe terminar en "?"
- Sin clickbait, sin exclamaciones

question:
- Pregunta más concreta y específica que el title
- Distinta al title (no puede ser la misma pregunta reformulada)
- Entre 80 y 160 caracteres
- Termina en "?"

card_summary:
- 1-2 frases que capturan la tensión central del debate
- Entre 100 y 220 caracteres
- No revela una respuesta, mantiene la ambigüedad

context:
- Entre 180 y 300 palabras
- Presenta el conflicto sin resolverlo, sin tomar partido
- Sin frases en primera persona ("yo creo", "está claro que", "evidentemente")
- Sin sensacionalismo ni juicios de valor implícitos
- La pregunta debe ser genuinamente debatible: dos o más posturas legítimas y defendibles
- El tono y la voz deben reflejar la perspectiva del perfil asignado (ver rasgos abajo)
- Solo en español, lenguaje accesible pero no simplista

PERFILES Y VOZ:
${profileSections}

Genera los 5 debates completos en el orden en que aparecen arriba. Para cada uno incluye todos los campos especificados. No omitas ningún campo ni debate.`;
}
