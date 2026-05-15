/**
 * Prompt 3…N — Single debate generation + inline validation
 * One call per assigned persona. Claude already has full context from
 * prompts 1 (news list) and 2 (assignments) via --continue.
 *
 * @param {number} slotIndex   0-based index of the assignment (0 = first pair)
 * @param {Object} persona     { id, username, specialty, bio, tagline, traits }
 * @param {string} publishedAt ISO timestamp
 * @returns {string}
 */
export function buildDebatePrompt(slotIndex, persona, publishedAt) {
  const traitsList = Array.isArray(persona.traits) && persona.traits.length
    ? persona.traits.join(', ')
    : persona.specialty;

  return `Genera el debate número ${slotIndex + 1} de la sesión.

Usa la asignación ${slotIndex + 1} que acabas de hacer (noticia → @${persona.username}).

VOZ DEL PERFIL @${persona.username}:
- Especialidad: ${persona.specialty}
- Bio: ${persona.bio}
- Tagline: "${persona.tagline}"
- Rasgos de escritura: ${traitsList}

El campo "context" debe estar escrito completamente en la voz de este perfil. No es un resumen neutro — es cómo ESTE personaje interpreta y presenta el tema.

REGLAS DE CALIDAD (verifica antes de responder):
✓ title: termina en "?", entre 60 y 120 caracteres
✓ question: entre 80 y 160 caracteres, distinta del title, termina en "?"
✓ card_summary: entre 100 y 220 caracteres
✓ context: entre 180 y 300 palabras, en la voz del perfil
✓ source_url: URL real que comienza con https://
✓ Ningún campo vacío

Devuelve ÚNICAMENTE el JSON del debate. Sin texto antes ni después.

{
  "persona_id": ${persona.id},
  "title": "¿...?",
  "question": "¿...?",
  "card_summary": "...",
  "context": "...",
  "source_name": "...",
  "source_url": "https://...",
  "published_at": "${publishedAt}",
  "generation_model": "claude"
}`;
}
