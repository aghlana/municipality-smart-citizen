import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import multer from 'multer';
import rateLimit from 'express-rate-limit';
import path from 'node:path';
import fs from 'node:fs';
import { fileURLToPath } from 'node:url';
import { pool } from './db.js';
import { requireAuth } from './auth.js';

dotenv.config();
if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32 ||
    process.env.JWT_SECRET.startsWith('REPLACE_')) {
  console.warn('WARNING: Set a long random JWT_SECRET in .env before use.');
}
const app = express();
app.use(helmet({ crossOriginResourcePolicy: { policy: 'cross-origin' } }));
const origin = process.env.CLIENT_ORIGIN || '*';
app.use(cors({ origin: origin === '*' ? true : origin.split(',').map(s => s.trim()) }));
app.use(express.json({ limit: '1mb' }));
app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300 }));
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const uploadDir = path.resolve(__dirname, '../uploads');
fs.mkdirSync(uploadDir, { recursive: true });
const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, uploadDir),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, `${Date.now()}-${Math.random().toString(36).slice(2)}${ext}`);
  }
});
const upload = multer({
  storage,
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = ['image/jpeg', 'image/png', 'image/webp'];
    cb(allowed.includes(file.mimetype) ? null : new Error('يسمح فقط بصور JPG وPNG وWebP'), allowed.includes(file.mimetype));
  }
});
app.use('/uploads', express.static(uploadDir, { dotfiles: 'deny', index: false }));

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.post('/api/auth/register', async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body || {};
    if (!name?.trim() || !email?.trim() || typeof password !== 'string' || password.length < 8) {
      return res.status(400).json({ error: 'أدخل الاسم والبريد وكلمة مرور من 8 أحرف على الأقل' });
    }
    const hash = await bcrypt.hash(password, 12);
    const result = await pool.query(
      'INSERT INTO users(name,email,phone,password_hash) VALUES($1,$2,$3,$4) RETURNING id,name,email,phone,role',
      [name.trim(), email.trim().toLowerCase(), phone?.trim() || null, hash]
    );
    const user = result.rows[0];
    const token = jwt.sign({ sub: String(user.id), role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.status(201).json({ token, user });
  } catch (e) {
    if (e.code === '23505') return res.status(409).json({ error: 'البريد الإلكتروني مسجل مسبقًا' });
    next(e);
  }
});

app.post('/api/auth/login', async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    const result = await pool.query('SELECT * FROM users WHERE email=$1', [(email || '').trim().toLowerCase()]);
    const userRow = result.rows[0];
    if (!userRow || !(await bcrypt.compare(password || '', userRow.password_hash))) {
      return res.status(401).json({ error: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' });
    }
    const user = { id: userRow.id, name: userRow.name, email: userRow.email, phone: userRow.phone, role: userRow.role };
    const token = jwt.sign({ sub: String(user.id), role: user.role }, process.env.JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (e) { next(e); }
});

app.get('/api/reports', requireAuth, async (req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id,title,description,category,latitude,longitude,image_path,status,created_at
       FROM reports WHERE user_id=$1 ORDER BY created_at DESC LIMIT 100`,
      [req.user.sub]
    );
    res.json({ reports: result.rows });
  } catch (e) { next(e); }
});

app.post('/api/reports', requireAuth, upload.single('image'), async (req, res, next) => {
  try {
    const { title, description, category, latitude, longitude } = req.body;
    if (!title?.trim() || !description?.trim() || !category?.trim()) {
      return res.status(400).json({ error: 'العنوان والوصف والتصنيف مطلوبة' });
    }
    const lat = latitude === undefined || latitude === '' ? null : Number(latitude);
    const lng = longitude === undefined || longitude === '' ? null : Number(longitude);
    if ((lat !== null && (!Number.isFinite(lat) || lat < -90 || lat > 90)) ||
        (lng !== null && (!Number.isFinite(lng) || lng < -180 || lng > 180))) {
      return res.status(400).json({ error: 'إحداثيات الموقع غير صحيحة' });
    }
    const imagePath = req.file ? `/uploads/${req.file.filename}` : null;
    const result = await pool.query(
      `INSERT INTO reports(user_id,title,description,category,latitude,longitude,image_path)
       VALUES($1,$2,$3,$4,$5,$6,$7)
       RETURNING id,title,description,category,latitude,longitude,image_path,status,created_at`,
      [req.user.sub, title.trim(), description.trim(), category.trim(), lat, lng, imagePath]
    );
    res.status(201).json({ report: result.rows[0] });
  } catch (e) { next(e); }
});

app.use((err, _req, res, _next) => {
  console.error(err);
  if (err instanceof multer.MulterError) return res.status(400).json({ error: 'تعذر رفع الملف أو تجاوز الحجم المسموح (8MB)' });
  res.status(500).json({ error: 'حدث خطأ داخلي في الخادم' });
});

const port = Number(process.env.PORT || 3000);
app.listen(port, '0.0.0.0', () => console.log(`Municipality API listening on ${port}`));
