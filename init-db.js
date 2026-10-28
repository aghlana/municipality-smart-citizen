import fs from 'node:fs/promises';
import { pool } from './db.js';
try {
  const sql = await fs.readFile(new URL('../db/schema.sql', import.meta.url), 'utf8');
  await pool.query(sql);
  console.log('Database schema initialized.');
} catch (e) {
  console.error('Database initialization failed:', e.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
