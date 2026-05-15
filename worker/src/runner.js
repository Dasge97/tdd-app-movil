import { v4 as uuidv4 } from 'uuid';
import { getPersonaRotation, calculateSlots, enrichPersona } from './personas.js';
import { getRecentTopics } from './context.js';
import { buildSearchPrompt } from './prompts/p1-search.js';
import { buildSelectionPrompt } from './prompts/p2-select.js';
import { buildDebatePrompt } from './prompts/p3-debate.js';
import { runSession } from './session.js';
import { validateOne } from './validator.js';
import { publish } from './publisher.js';

/**
 * Orchestrates the full worker execution cycle:
 *   1. Load context (recent topics + persona rotation)
 *   2. Prompt 1: search for today's news
 *   3. Prompt 2: select 5 topics and assign to personas
 *   4. Prompt 3…N: one debate per persona (generate + validate inline)
 *   5. Publish all valid debates to the backend
 *
 * @param {Object} config   Worker configuration from the backend API
 * @param {Object} logger   Winston logger instance
 */
export async function run(config, logger) {
  const runId = uuidv4();
  logger.info(`Run iniciado: ${runId}`);

  const dedupDays = config.dedup_days ?? 14;
  const rotationLimitDays = config.rotation_limit_days ?? 3;
  const targetDebates = config.target_debates ?? 5;

  logger.info(`Config: dedup_days=${dedupDays}, rotation_limit=${rotationLimitDays}, target=${targetDebates}`);

  // ── 1. Load context ──────────────────────────────────────────────────────────
  const [recentTopics, personasWithDays] = await Promise.all([
    getRecentTopics(dedupDays),
    getPersonaRotation(),
  ]);

  logger.info(`Temas recientes: ${recentTopics.length} | Personas en BD: ${personasWithDays.length}`);

  if (personasWithDays.length === 0) {
    throw new Error('No se encontraron personas IA en la base de datos.');
  }

  const slots = calculateSlots(personasWithDays, rotationLimitDays, targetDebates);
  const allPersonas = [...slots.mandatory, ...slots.available].map(enrichPersona);

  logger.info(`Slots — ${allPersonas.length} debates a generar: [${allPersonas.map((p) => p.username).join(', ')}]`);

  const publishedAt = new Date().toISOString();

  // ── 2. Build prompt sequence ─────────────────────────────────────────────────
  // p1 + p2 run first to establish context, then one p3 per persona
  const p1 = buildSearchPrompt(recentTopics);
  const p2 = buildSelectionPrompt(slots);
  const debatePrompts = allPersonas.map((persona, i) =>
    buildDebatePrompt(i, persona, publishedAt),
  );

  const allPrompts = [p1, p2, ...debatePrompts];
  logger.info(`${allPrompts.length} prompts en total (2 de contexto + ${debatePrompts.length} debates)`);

  // ── 3. Run AI session ────────────────────────────────────────────────────────
  // session.js handles --continue between turns so context is preserved
  const responses = await runSession(allPrompts, logger);

  // responses[0] = p1 output, responses[1] = p2 output
  // responses[2..N] = one JSON debate each
  const debateResponses = responses.slice(2);

  // ── 4. Validate each debate individually ─────────────────────────────────────
  const debates = [];
  for (let i = 0; i < debateResponses.length; i++) {
    const persona = allPersonas[i];
    try {
      const debate = validateOne(debateResponses[i]);
      debates.push(debate);
      logger.info(`Debate ${i + 1}/${debateResponses.length} (@${persona.username}) validado OK`);
    } catch (err) {
      logger.error(`Debate ${i + 1}/${debateResponses.length} (@${persona.username}) inválido — se omite: ${err.message}`);
      logger.error(`Output raw: ${debateResponses[i].slice(0, 300)}`);
    }
  }

  if (debates.length === 0) {
    throw new Error('Ningún debate pasó la validación.');
  }

  logger.info(`${debates.length}/${debateResponses.length} debates válidos listos para publicar`);

  // ── 5. Publish ────────────────────────────────────────────────────────────────
  const result = await publish(debates, runId, logger);

  logger.info(`Run ${runId} completado con éxito. ${debates.length} debates publicados.`);

  return { runId, debatesCount: debates.length, backendResponse: result };
}
