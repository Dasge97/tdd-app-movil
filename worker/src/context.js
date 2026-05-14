import { query } from './db.js';

/**
 * Returns debates published in the last `dedupDays` days.
 * Used to avoid repeating topics that were recently covered.
 *
 * @param {number} dedupDays  Number of days to look back
 * @returns {Promise<Array<{ title: string, dayDate: string }>>}
 */
export async function getRecentTopics(dedupDays = 14) {
  const rows = await query(
    `SELECT title, DATE_FORMAT(day_date, '%Y-%m-%d') AS day_date
     FROM debates
     WHERE day_date >= DATE_SUB(NOW(), INTERVAL ? DAY)
     ORDER BY day_date DESC`,
    [dedupDays],
  );

  return rows.map((row) => ({
    title: row.title,
    dayDate: row.day_date,
  }));
}

/**
 * Returns, for each AI persona, the number of days since their last debate.
 * Useful for additional context in logs or extended reporting.
 *
 * @returns {Promise<Array<{ username: string, daysSince: number|null }>>}
 */
export async function getPersonaDaysSince() {
  const rows = await query(`
    SELECT
      u.username,
      CAST(DATEDIFF(NOW(), MAX(d.day_date)) AS SIGNED) AS days_since
    FROM users u
    LEFT JOIN debates d ON d.created_by = u.id
    WHERE u.is_ai_persona = 1
    GROUP BY u.username
    ORDER BY days_since DESC
  `);

  return rows.map((row) => ({
    username: row.username,
    daysSince: row.days_since === null ? null : Number(row.days_since),
  }));
}
