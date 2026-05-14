/**
 * Prompt 4 — Validation & JSON output
 * Instructs the AI to review and return the final validated JSON.
 *
 * @param {Object} personaIds   Map of username → database ID
 * @returns {string}
 */
export function buildValidationPrompt(personaIds) {
  const idList = Object.entries(personaIds)
    .map(([username, id]) => `- @${username}: id=${id}`)
    .join('\n');

  const publishedAt = new Date().toISOString();
  const model = process.env.OPENCODE_MODEL_ID || 'gpt-4o';

  return `Revisa los 5 debates que acabas de generar y verifica que todos cumplan las reglas de calidad.

CHECKLIST DE VALIDACIÓN:
✓ Exactamente 5 debates, uno por perfil asignado
✓ title: termina en "?", entre 60 y 120 caracteres
✓ question: entre 80 y 160 caracteres, distinta del title, termina en "?"
✓ card_summary: entre 100 y 220 caracteres
✓ context: entre 180 y 300 palabras
✓ source_url: URL válida (comienza con https://)
✓ source_name: nombre de la fuente (ej: "El País", "BBC", "Reuters")
✓ Sin dos debates con el mismo persona_id
✓ El tono de cada context refleja la voz del perfil asignado
✓ Ningún context toma partido explícitamente

Si detectas que algún campo no cumple las reglas, corrígelo directamente en el JSON de salida.

IDs de perfiles en base de datos:
${idList}

Devuelve ÚNICAMENTE el JSON final con el schema exacto siguiente.
No incluyas texto, explicaciones ni markdown fuera del bloque JSON.
El JSON debe comenzar directamente con { y terminar con }.

{
  "debates": [
    {
      "persona_id": <número entero>,
      "title": "¿...?",
      "question": "¿...?",
      "card_summary": "...",
      "context": "...",
      "source_name": "...",
      "source_url": "https://...",
      "published_at": "${publishedAt}",
      "generation_model": "${model}"
    }
  ]
}`;
}
