import express from 'express';
import { spawn } from 'child_process';

export const imageProxyRouter = express.Router();

imageProxyRouter.get('/', (req, res) => {
  const { url } = req.query;

  if (!url || typeof url !== 'string') {
    return res.status(400).json({ error: '"url" query param is required' });
  }

  try { new URL(url); } catch {
    return res.status(400).json({ error: 'Invalid URL' });
  }

  if (!/^https?:/.test(url)) {
    return res.status(400).json({ error: 'Only http/https URLs are allowed' });
  }

  const parsed = new URL(url);
  const referer = `${parsed.protocol}//${parsed.hostname}/`;

  // --write-out appends the 3-digit HTTP status code to stdout after the body.
  // We slice the last 3 bytes to get the code without touching stderr at all.
  const args = [
    '-s', '-L',
    '--http1.1',
    '--max-time', '10',
    '-A', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    '-e', referer,
    '-H', 'Accept: image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    '-H', 'Accept-Language: en-US,en;q=0.9',
    '-H', 'sec-fetch-dest: image',
    '-H', 'sec-fetch-mode: no-cors',
    '-H', 'sec-fetch-site: same-origin',
    '-o', '-',
    '--write-out', '%{http_code}',
    url,
  ];

  const ext = parsed.pathname.split('.').pop().toLowerCase();
  const ctMap = { jpg: 'image/jpeg', jpeg: 'image/jpeg', png: 'image/png', webp: 'image/webp', gif: 'image/gif', avif: 'image/avif' };
  const contentType = ctMap[ext] || 'image/jpeg';

  const chunks = [];
  const curl = spawn('curl', args);

  curl.stdout.on('data', (chunk) => chunks.push(chunk));

  curl.on('close', (code) => {
    if (code !== 0) {
      console.error(`[image-proxy] curl exited ${code} for ${url}`);
      if (!res.headersSent) return res.status(502).json({ error: `curl exited ${code}` });
      return;
    }

    const full = Buffer.concat(chunks);
    const httpCode = parseInt(full.slice(-3).toString('ascii'), 10);
    const body = full.slice(0, -3);

    if (httpCode !== 200) {
      console.error(`[image-proxy] upstream ${httpCode} for ${url}`);
      if (!res.headersSent) return res.status(502).json({ error: `Upstream ${httpCode}`, upstream_url: url });
      return;
    }

    res.setHeader('Content-Type', contentType);
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.status(200).send(body);
  });

  curl.on('error', (err) => {
    console.error(`[image-proxy] spawn error: ${err.message}`);
    if (!res.headersSent) res.status(502).json({ error: err.message });
  });
});
