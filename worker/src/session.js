import fetch from 'node-fetch';

const OPENAI_API_URL = 'https://api.openai.com/v1/chat/completions';
const PROMPT_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes per prompt

/**
 * Calls the OpenAI Chat Completions API with the full conversation history.
 * Maintains context across multiple prompts by appending to conversationHistory.
 *
 * @param {string} prompt               The user message for this turn
 * @param {Array}  conversationHistory  Array of {role, content} from previous turns
 * @param {Object} logger               Winston logger instance
 * @returns {Promise<string>}           The assistant's response text
 */
async function callOpenAI(prompt, conversationHistory, logger) {
  const apiKey = process.env.OPENCODE_API_KEY;
  if (!apiKey) {
    throw new Error('OPENCODE_API_KEY no está configurada');
  }

  const model = process.env.OPENCODE_MODEL_ID || 'gpt-4o';

  const messages = [
    ...conversationHistory,
    { role: 'user', content: prompt },
  ];

  logger.debug(`Llamando OpenAI con modelo ${model}, ${messages.length} mensajes en contexto`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), PROMPT_TIMEOUT_MS);

  let response;
  try {
    response = await fetch(OPENAI_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
        temperature: 0.8,
        max_tokens: 4096,
      }),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`OpenAI API error ${response.status}: ${body}`);
  }

  const data = await response.json();

  if (!data.choices || data.choices.length === 0) {
    throw new Error('OpenAI devolvió una respuesta vacía (sin choices)');
  }

  const content = data.choices[0].message?.content;
  if (!content) {
    throw new Error('OpenAI devolvió un mensaje sin contenido');
  }

  logger.debug(`Tokens usados: prompt=${data.usage?.prompt_tokens}, completion=${data.usage?.completion_tokens}`);

  return content;
}

/**
 * Runs a multi-turn conversation with the AI model, sending all prompts
 * sequentially in a single session with shared context.
 *
 * @param {string[]} prompts   Ordered array of prompt strings (4 prompts)
 * @param {Object}   logger    Winston logger instance
 * @returns {Promise<string>}  The raw output of the last prompt (Prompt 4 JSON)
 */
export async function runSession(prompts, logger) {
  if (!prompts || prompts.length === 0) {
    throw new Error('No hay prompts para ejecutar');
  }

  const conversationHistory = [];
  const responses = [];

  for (let i = 0; i < prompts.length; i++) {
    const promptNum = i + 1;
    logger.info(`Ejecutando Prompt ${promptNum}/${prompts.length}...`);

    const response = await callOpenAI(prompts[i], conversationHistory, logger);

    // Append this turn to the history so the next prompt has full context
    conversationHistory.push({ role: 'user', content: prompts[i] });
    conversationHistory.push({ role: 'assistant', content: response });

    responses.push(response);
    logger.info(`Prompt ${promptNum}/${prompts.length} completado (${response.length} caracteres)`);
  }

  // Return the last response — this is the validated JSON from Prompt 4
  return responses[responses.length - 1];
}
