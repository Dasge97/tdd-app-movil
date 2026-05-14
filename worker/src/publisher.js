import fetch from 'node-fetch';

const PUBLISH_TIMEOUT_MS = 30_000; // 30 seconds

/**
 * Sends the validated debates to the backend's worker publish endpoint.
 *
 * @param {Array}  debates  Validated array of debate objects
 * @param {string} runId    UUID of the current worker run
 * @param {Object} logger   Winston logger instance
 * @returns {Promise<Object>} Backend response JSON
 */
export async function publish(debates, runId, logger) {
  const baseUrl = process.env.BACKEND_API_BASE_URL;
  const apiKey = process.env.WORKER_API_KEY;

  if (!baseUrl) throw new Error('BACKEND_API_BASE_URL no está configurada');
  if (!apiKey) throw new Error('WORKER_API_KEY no está configurada');

  const url = `${baseUrl}/api/v1/worker/publish`;

  logger.info(`Publicando ${debates.length} debates en ${url} (run_id: ${runId})`);

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), PUBLISH_TIMEOUT_MS);

  let response;
  try {
    response = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Worker-Key': apiKey,
      },
      body: JSON.stringify({
        debates,
        run_id: runId,
      }),
      signal: controller.signal,
    });
  } finally {
    clearTimeout(timeoutId);
  }

  if (!response.ok) {
    const body = await response.text();
    throw new Error(
      `Backend publish failed: HTTP ${response.status} — ${body}`,
    );
  }

  const result = await response.json();
  logger.info(`Backend confirmó publicación: ${JSON.stringify(result)}`);

  return result;
}
