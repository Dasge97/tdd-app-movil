import { v4 as uuidv4 } from 'uuid';
import { getPersonaRotation, calculateSlots, enrichPersona } from './personas.js';
import { getRecentTopics } from './context.js';
import { buildSearchPrompt } from './prompts/p1-search.js';
import { buildSelectionPrompt } from './prompts/p2-select.js';
import { buildGenerationPrompt } from './prompts/p3-generate.js';
import { buildValidationPrompt } from './prompts/p4-validate.js';
import { runSession } from './session.js';
import { validate } from './validator.js';
import { publish } from './publisher.js';

/**
 * Orchestrates the full worker execution cycle:
 *   1. Load context from DB (recent topics + persona rotation)
 *   2. Build 4 sequential prompts
 *   3. Run the AI session (4-prompt conversation with shared context)
 *   4. Validate the JSON output
 *   5. Publish the debates to the backend
 *
 * @param {Object} config   Worker configuration from the backend API
 * @param {Object} logger   Winston logger instance
 * @returns {Promise<{ runId: string, debatesCount: number }>}
 */
export async function run(config, logger) {
  const runId = uuidv4();
  logger.info(`Run iniciado: ${runId}`);

  // ── 1. Load context ────────────────────────────────────────────────────────

  const dedupDays = config.dedup_days ?? 14;
  const rotationLimitDays = config.rotation_limit_days ?? 3;
  const targetDebates = config.target_debates ?? 5;

  logger.info(`Config: dedup_days=${dedupDays}, rotation_limit=${rotationLimitDays}, target=${targetDebates}`);

  // These two queries can run in parallel
  const [recentTopics, personasWithDays] = await Promise.all([
    getRecentTopics(dedupDays),
    getPersonaRotation(),
  ]);

  logger.info(`Temas recientes: ${recentTopics.length} | Personas en BD: ${personasWithDays.length}`);

  if (personasWithDays.length === 0) {
    throw new Error(
      'No se encontraron personas IA en la base de datos (is_ai_persona = 1). ' +
      'Asegúrate de que los fixtures están cargados.',
    );
  }

  // Determine which personas must publish today and which are optional
  const slots = calculateSlots(personasWithDays, rotationLimitDays, targetDebates);

  logger.info(
    `Slots — obligatorios: [${slots.mandatory.map((p) => p.username).join(', ')}] | ` +
    `disponibles: [${slots.available.map((p) => p.username).join(', ')}]`,
  );

  // Build persona IDs map for Prompt 4 (username → database ID)
  const personaIds = {};
  for (const p of personasWithDays) {
    personaIds[p.username] = p.id;
  }

  // ── 2. Build prompts ───────────────────────────────────────────────────────

  const p1 = buildSearchPrompt(recentTopics);
  const p2 = buildSelectionPrompt(slots);

  // For Prompt 3 we provide enriched persona data with bio/tagline/traits.
  // The actual noticia details will be picked by the model in Prompt 2; here we
  // give the model the persona voice information. The model carries the noticia
  // context from its conversation history.
  const allSelectedPersonas = [...slots.mandatory, ...slots.available];
  const assignedPersonas = allSelectedPersonas.map((p) => {
    const enriched = enrichPersona(p);
    return {
      persona: enriched,
      // Placeholder: the model already knows the noticia from prompt 2 context
      noticia: {
        titulo: '(ver selección del paso anterior)',
        fuente: '',
        url: '',
        contexto: '',
      },
    };
  });

  const p3 = buildGenerationPrompt(assignedPersonas);
  const p4 = buildValidationPrompt(personaIds);

  logger.info('4 prompts construidos. Iniciando sesión IA...');

  // ── 3. Run AI session ──────────────────────────────────────────────────────

  const rawOutput = await runSession([p1, p2, p3, p4], logger);

  logger.info(`Sesión IA completada. Output: ${rawOutput.length} caracteres`);

  // ── 4. Validate output ─────────────────────────────────────────────────────

  logger.info('Validando output del modelo...');
  let debates;
  try {
    debates = validate(rawOutput);
  } catch (validationError) {
    // Log the raw output for debugging before re-throwing
    logger.error('Validación fallida. Output raw del modelo:');
    logger.error(rawOutput.slice(0, 2000)); // First 2000 chars for logs
    throw validationError;
  }

  logger.info(`Validación OK — ${debates.length} debates listos para publicar`);

  // ── 5. Publish ─────────────────────────────────────────────────────────────

  const result = await publish(debates, runId, logger);

  logger.info(`Run ${runId} completado con éxito. ${debates.length} debates publicados.`);

  return {
    runId,
    debatesCount: debates.length,
    backendResponse: result,
  };
}
