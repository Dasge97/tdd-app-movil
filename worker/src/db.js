import mysql from 'mysql2/promise';

let pool = null;

/**
 * Returns (or creates) the MySQL connection pool.
 * Lazy-initialised on first call.
 */
export function getPool() {
  if (pool) return pool;

  pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306', 10),
    database: process.env.DB_NAME || 'tdd_app',
    user: process.env.DB_USER || 'tdd_user',
    password: process.env.DB_PASSWORD || 'tdd_pass',
    waitForConnections: true,
    connectionLimit: 5,
    queueLimit: 0,
    timezone: '+00:00',
    charset: 'utf8mb4',
  });

  return pool;
}

/**
 * Executes a parameterised query and returns the rows array.
 * @param {string} sql
 * @param {Array} params
 * @returns {Promise<Array>}
 */
export async function query(sql, params = []) {
  const db = getPool();
  const [rows] = await db.execute(sql, params);
  return rows;
}
