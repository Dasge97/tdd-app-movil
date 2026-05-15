import fetch from 'node-fetch';

async function apiFetch(path) {
  const baseUrl = process.env.BACKEND_API_BASE_URL;
  const apiKey = process.env.WORKER_API_KEY;

  const response = await fetch(`${baseUrl}${path}`, {
    headers: { 'X-Worker-Key': apiKey, 'Accept': 'application/json' },
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Worker API error ${response.status} ${path}: ${body}`);
  }

  return response.json();
}

/**
 * Returns debates published in the last `dedupDays` days.
 * Used to avoid repeating topics that were recently covered.
 *
 * @param {number} dedupDays
 * @returns {Promise<Array<{ title: string, dayDate: string }>>}
 */
export async function getRecentTopics(dedupDays = 14) {
  const rows = await apiFetch(`/api/v1/worker/recent-topics?days=${dedupDays}`);

  return rows.map((row) => ({
    title: row.title,
    dayDate: row.day_date,
  }));
}
