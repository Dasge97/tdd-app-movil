/**
 * Prompt 2 — Selection
 * Instructs the AI to pick exactly 5 news items from the previous list
 * and assign each to a specific persona based on specialty fit.
 *
 * @param {{ mandatory: Array, available: Array }} slots
 * @returns {string}
 */
export function buildSelectionPrompt(slots) {
  const allPersonas = [...slots.mandatory, ...slots.available];
  const mandatoryUsernames = slots.mandatory.map((p) => p.username);

  const personaLines = allPersonas.map((p) => {
    const daysSinceLabel =
      p.daysSince === Infinity || p.daysSince === null
        ? 'nunca ha publicado'
        : `${p.daysSince} días sin publicar`;
    const mandatory = mandatoryUsernames.includes(p.username) ? ' ⚠️ OBLIGATORIO' : '';
    return `- @${p.username} (especialidad: ${p.specialty}) — ${daysSinceLabel}${mandatory}`;
  }).join('\n');

  const mandatorySection =
    mandatoryUsernames.length > 0
      ? `\nPERFILES OBLIGATORIOS que DEBEN aparecer en la selección final: ${mandatoryUsernames.map((u) => '@' + u).join(', ')}\n`
      : '';

  return `De las noticias que acabas de encontrar, selecciona exactamente 5 y asigna cada una a uno de los perfiles disponibles.

PERFILES DISPONIBLES:
${personaLines}
${mandatorySection}
REGLAS DE SELECCIÓN:
1. Selecciona exactamente 5 noticias distintas de la lista anterior.
2. Asigna cada noticia al perfil cuya especialidad encaje mejor con el tema.
3. Ningún perfil puede recibir más de una noticia.
4. Si hay perfiles marcados como ⚠️ OBLIGATORIO, deben estar entre los 5 asignados.
5. Justifica la asignación en una frase: por qué esa noticia encaja con ese perfil.

Formato de respuesta (una línea por par):
Noticia [número]: "[titular]" → @[username] — [justificación en una frase]

Selecciona las 5 noticias que generen el debate más rico y variado temáticamente.`;
}
