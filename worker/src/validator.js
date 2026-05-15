/**
 * Required fields for each debate object.
 */
const REQUIRED_FIELDS = [
  'persona_id',
  'title',
  'question',
  'card_summary',
  'context',
  'source_name',
  'source_url',
  'published_at',
];

/**
 * Attempts to extract a JSON object or array from a raw string that may
 * contain surrounding text, markdown code fences, etc.
 *
 * @param {string} raw
 * @returns {any} Parsed JSON value
 */
function extractJson(raw) {
  if (!raw || typeof raw !== 'string') {
    throw new Error('El output del modelo está vacío o no es una cadena de texto');
  }

  // Strip markdown code fences if present
  const stripped = raw.replace(/```(?:json)?\s*/gi, '').replace(/```/g, '').trim();

  // Try direct parse first
  try {
    return JSON.parse(stripped);
  } catch (_) {
    // Intentionally empty — will try extraction below
  }

  // Find the first '{' or '[' and try to parse from there
  const braceIdx = stripped.indexOf('{');
  const bracketIdx = stripped.indexOf('[');

  let startIdx = -1;
  if (braceIdx === -1 && bracketIdx === -1) {
    throw new Error('No se encontró ningún objeto JSON en el output del modelo');
  } else if (braceIdx === -1) {
    startIdx = bracketIdx;
  } else if (bracketIdx === -1) {
    startIdx = braceIdx;
  } else {
    startIdx = Math.min(braceIdx, bracketIdx);
  }

  // Also find the last matching closing character
  const lastBrace = stripped.lastIndexOf('}');
  const lastBracket = stripped.lastIndexOf(']');
  const endIdx = Math.max(lastBrace, lastBracket);

  if (endIdx <= startIdx) {
    throw new Error('El JSON en el output del modelo parece estar truncado o malformado');
  }

  const candidate = stripped.slice(startIdx, endIdx + 1);

  try {
    return JSON.parse(candidate);
  } catch (err) {
    throw new Error(`JSON malformado en el output del modelo: ${err.message}`);
  }
}

/**
 * Counts the number of words in a string.
 */
function wordCount(str) {
  return str.trim().split(/\s+/).filter(Boolean).length;
}

/**
 * Validates the raw JSON output from the AI session.
 * Throws a descriptive Error if validation fails.
 * Returns the debates array on success.
 *
 * @param {string} jsonOutput  Raw string output from the model (Prompt 4)
 * @returns {Array}            Validated array of debate objects
 */
export function validate(jsonOutput) {
  const parsed = extractJson(jsonOutput);

  // Accept either { debates: [...] } or a bare array
  let debates;
  if (Array.isArray(parsed)) {
    debates = parsed;
  } else if (parsed && Array.isArray(parsed.debates)) {
    debates = parsed.debates;
  } else {
    throw new Error(
      'El JSON no contiene una propiedad "debates" que sea un array',
    );
  }

  if (debates.length !== 5) {
    throw new Error(
      `Se esperaban exactamente 5 debates, pero se encontraron ${debates.length}`,
    );
  }

  const seenPersonaIds = new Set();

  debates.forEach((debate, idx) => {
    const pos = `Debate ${idx + 1}`;

    // Check required fields
    for (const field of REQUIRED_FIELDS) {
      if (debate[field] === undefined || debate[field] === null || debate[field] === '') {
        throw new Error(`${pos}: falta el campo requerido "${field}"`);
      }
    }

    // persona_id must be a number
    if (typeof debate.persona_id !== 'number' || !Number.isInteger(debate.persona_id)) {
      throw new Error(`${pos}: persona_id debe ser un entero, se recibió: ${JSON.stringify(debate.persona_id)}`);
    }

    // No duplicate persona_ids
    if (seenPersonaIds.has(debate.persona_id)) {
      throw new Error(`${pos}: persona_id ${debate.persona_id} está duplicado`);
    }
    seenPersonaIds.add(debate.persona_id);

    // title: 60–120 chars, ends with "?"
    const titleLen = debate.title.length;
    if (titleLen < 60 || titleLen > 120) {
      throw new Error(
        `${pos}: title tiene ${titleLen} caracteres (debe estar entre 60 y 120)`,
      );
    }
    if (!debate.title.trim().endsWith('?')) {
      throw new Error(`${pos}: title debe terminar en "?"`);
    }

    // question: 80–160 chars
    const questionLen = debate.question.length;
    if (questionLen < 80 || questionLen > 160) {
      throw new Error(
        `${pos}: question tiene ${questionLen} caracteres (debe estar entre 80 y 160)`,
      );
    }

    // card_summary: 100–220 chars
    const summaryLen = debate.card_summary.length;
    if (summaryLen < 100 || summaryLen > 220) {
      throw new Error(
        `${pos}: card_summary tiene ${summaryLen} caracteres (debe estar entre 100 y 220)`,
      );
    }

    // context: 180–300 words
    const contextWords = wordCount(debate.context);
    if (contextWords < 180 || contextWords > 300) {
      throw new Error(
        `${pos}: context tiene ${contextWords} palabras (debe estar entre 180 y 300)`,
      );
    }

    // source_url: must start with http
    if (!debate.source_url.startsWith('http')) {
      throw new Error(
        `${pos}: source_url no parece una URL válida: "${debate.source_url}"`,
      );
    }
  });

  return debates;
}

/**
 * Validates a single debate object from a raw string.
 * Used when each prompt generates one debate individually.
 *
 * @param {string} jsonOutput  Raw string output from the model
 * @returns {Object}           Validated debate object
 */
export function validateOne(jsonOutput) {
  const parsed = extractJson(jsonOutput);

  // Accept bare object or { debates: [single] } or [single]
  let debate;
  if (Array.isArray(parsed)) {
    if (parsed.length !== 1) {
      throw new Error(`Se esperaba 1 debate, se encontraron ${parsed.length}`);
    }
    debate = parsed[0];
  } else if (parsed && Array.isArray(parsed.debates)) {
    if (parsed.debates.length !== 1) {
      throw new Error(`Se esperaba 1 debate, se encontraron ${parsed.debates.length}`);
    }
    debate = parsed.debates[0];
  } else if (parsed && typeof parsed === 'object' && !Array.isArray(parsed)) {
    debate = parsed;
  } else {
    throw new Error('No se encontró un objeto de debate válido en el output');
  }

  for (const field of REQUIRED_FIELDS) {
    if (debate[field] === undefined || debate[field] === null || debate[field] === '') {
      throw new Error(`Falta el campo requerido "${field}"`);
    }
  }

  if (typeof debate.persona_id !== 'number' || !Number.isInteger(debate.persona_id)) {
    throw new Error(`persona_id debe ser un entero, se recibió: ${JSON.stringify(debate.persona_id)}`);
  }

  const titleLen = debate.title.length;
  if (titleLen < 60 || titleLen > 120) {
    throw new Error(`title tiene ${titleLen} caracteres (debe estar entre 60 y 120)`);
  }
  if (!debate.title.trim().endsWith('?')) {
    throw new Error('title debe terminar en "?"');
  }

  const questionLen = debate.question.length;
  if (questionLen < 80 || questionLen > 160) {
    throw new Error(`question tiene ${questionLen} caracteres (debe estar entre 80 y 160)`);
  }

  const summaryLen = debate.card_summary.length;
  if (summaryLen < 100 || summaryLen > 220) {
    throw new Error(`card_summary tiene ${summaryLen} caracteres (debe estar entre 100 y 220)`);
  }

  const contextWords = wordCount(debate.context);
  if (contextWords < 180 || contextWords > 300) {
    throw new Error(`context tiene ${contextWords} palabras (debe estar entre 180 y 300)`);
  }

  if (!debate.source_url.startsWith('http')) {
    throw new Error(`source_url no parece una URL válida: "${debate.source_url}"`);
  }

  return debate;
}
