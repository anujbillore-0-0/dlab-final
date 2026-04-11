/**
 * DLab — Excel → Supabase Product Uploader (Node.js)
 * npm install xlsx  →  node upload_products.mjs
 */

import { createRequire } from 'module';
const require = createRequire(import.meta.url);
const XLSX = require('xlsx');

// ╔══════════════════════════════════════════════════╗
// ║                  CONFIG                         ║
// ╚══════════════════════════════════════════════════╝

const EXCEL_FILE       = String.raw`C:\Users\Anuj Billore\Downloads\cleaned_products.xlsx`;
const SHEET_INDEX      = 0;
const SUPABASE_URL     = 'https://zzqeibxwasikdmdoijfb.supabase.co';
const SERVICE_ROLE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6cWVpYnh3YXNpa2RtZG9pamZiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTk5NDAxMCwiZXhwIjoyMDg3NTcwMDEwfQ._Al6n_Ai32m8p7gMXZO14xrVH5DGJTnRx0LJ1-EdPiI';

const COLUMN_MAP = {
  'ID':                '_id',
  'Name':              'name',
  'Short description': 'short_description',
  'Description':       'description',
  'Weight':            'weight',
  'Length':            'length',
  'Width':             'width',
  'Height':            'height',
  'Sale price':        'sale_price',
  'Regular price':     'regular_price',
  'Categories':        '_category_name',
  'Images':            '_images',
};

const BATCH_SIZE = 50;

// ╔══════════════════════════════════════════════════╗
// ║                  HELPERS                        ║
// ╚══════════════════════════════════════════════════╝

const HEADERS = {
  'apikey':        SERVICE_ROLE_KEY,
  'Authorization': `Bearer ${SERVICE_ROLE_KEY}`,
  'Content-Type':  'application/json',
  'Prefer':        'resolution=merge-duplicates,return=minimal',
};

const safe    = v  => { const s = v == null ? '' : String(v).trim(); return s || null; };
const toFloat = v  => { const s = safe(v); if (!s) return null; const n = parseFloat(s.replace(/[^\d.\-]/g,'')); return isNaN(n)?null:n; };
const toInt   = v  => { const f = toFloat(v); return f!=null ? Math.round(f) : null; };
const toImgs  = v  => { const s = safe(v); if (!s) return null; const a = s.split(/[,\n]/).map(u=>u.trim()).filter(Boolean); return a.length?a:null; };

const parentName  = name => name.split(' - ')[0].trim();
const variantLabel = name => { const p = name.split(' - '); p.shift(); return p.join(' - ').trim(); };

async function fetchCategories() {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/categories?select=id,name`, { headers: HEADERS });
  if (!r.ok) throw new Error(`Categories fetch failed: ${await r.text()}`);
  const rows = await r.json();
  return Object.fromEntries(rows.map(c => [c.name.toLowerCase(), c.id]));
}

async function upsertBatch(table, rows) {
  if (!rows.length) return 0;
  const allKeys    = [...new Set(rows.flatMap(r => Object.keys(r)))];
  const normalized = rows.map(r => Object.fromEntries(allKeys.map(k => [k, r[k] ?? null])));
  const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}`, {
    method: 'POST', headers: HEADERS, body: JSON.stringify(normalized),
  });
  if (!res.ok) {
    console.error(`  ✗ [${table}] ${res.status}: ${(await res.text()).slice(0,300)}`);
    return 0;
  }
  return rows.length;
}

// ╔══════════════════════════════════════════════════╗
// ║                    MAIN                         ║
// ╚══════════════════════════════════════════════════╝

async function main() {

  // 1. Read Excel
  console.log(`📂  Reading: ${EXCEL_FILE}`);
  let workbook;
  try { workbook = XLSX.readFile(EXCEL_FILE); }
  catch (e) { console.error(`✗ Cannot open: ${e.message}`); process.exit(1); }

  const sheetName = workbook.SheetNames[SHEET_INDEX];
  const rawRows   = XLSX.utils.sheet_to_json(workbook.Sheets[sheetName], { defval: '' });
  console.log(`   "${sheetName}": ${rawRows.length} rows found`);
  console.log(`   Columns: ${Object.keys(rawRows[0] ?? {}).join(', ')}`);

  // 2. Fetch categories
  console.log('\n🔍  Fetching categories …');
  let categories = {};
  try { categories = await fetchCategories(); console.log(`   ${Object.keys(categories).length} loaded`); }
  catch (e) { console.error(`  ✗ ${e.message}`); }

  // 3. Parse all rows
  const parsedRows = [];
  let skipped = 0;

  for (const excelRow of rawRows) {
    const row = {};
    let validId = true;

    for (const [col, dbCol] of Object.entries(COLUMN_MAP)) {
      const raw = safe(excelRow[col]);
      if      (dbCol === '_id')            { const v = toInt(raw); if (v==null){validId=false;break;} row.id=v; }
      else if (dbCol === '_category_name') { row._category_name = raw || null; }
      else if (dbCol === '_images')        { row.images = toImgs(raw); }
      else if (['regular_price','sale_price','weight','length','width','height'].includes(dbCol)) { row[dbCol] = toFloat(raw); }
      else if (raw !== null)               { row[dbCol] = raw; }
    }

    if (!validId || !row.id || !row.name) { skipped++; continue; }
    parsedRows.push(row);
  }
  console.log(`\n   ${parsedRows.length} rows parsed, ${skipped} skipped`);

  // 4. PASS 1 — Build parent map
  // A row is DEFINITELY a parent if:
  //   - has description, OR
  //   - has category, OR  
  //   - name has NO ' - ' (structurally cannot be a variant)
  const parentNameToId = {};
  for (const row of parsedRows) {
    const hasDesc  = !!row.description;
    const hasCat   = !!row._category_name;
    const noDash   = !row.name.includes(' - ');
    if (hasDesc || hasCat || noDash) {
      parentNameToId[row.name.trim()] = row.id;
    }
  }
  console.log(`\n   ${Object.keys(parentNameToId).length} parent products identified`);

  // 5. PASS 2 — Classify each row
  // Variant = has ' - ' AND no desc AND no cat AND guessed parent exists in map
  function isVariant(row) {
    if (!row.name.includes(' - ')) return false;
    if (row.description)           return false;
    if (row._category_name)        return false;
    return parentName(row.name) in parentNameToId;
  }

  const productRows      = [];
  const variantRows      = [];
  const variantParentIds = new Set();

  for (const row of parsedRows) {
    if (!isVariant(row)) {
      // ── Parent / Simple product ──
      const catName = row._category_name
        ? row._category_name.split(',')[0].trim().toLowerCase()
        : null;
      const catId = catName ? (categories[catName] ?? null) : null;

      if (catName && catId == null)
        console.log(`    ⚠  id=${row.id}: category "${row._category_name}" not found`);

      productRows.push({
        id:                row.id,
        name:              row.name,
        short_description: row.short_description || null,
        description:       row.description       || null,
        weight:            row.weight,
        length:            row.length,
        width:             row.width,
        height:            row.height,
        category_id:       catId,
        images:            row.images,
        is_variable:       false,          // corrected below
        sale_price:        row.sale_price,
        regular_price:     row.regular_price,
        is_active:         true,
      });

    } else {
      // ── Variant ──
      const pid = parentNameToId[parentName(row.name)]; // guaranteed to exist
      variantParentIds.add(pid);

      variantRows.push({
        id:            row.id,
        product_id:    pid,
        variant_name:  variantLabel(row.name),
        sale_price:    row.sale_price,
        regular_price: row.regular_price,
        weight:        row.weight,
        length:        row.length,
        width:         row.width,
        height:        row.height,
        images:        row.images,
        is_active:     true,
      });
    }
  }

  // 6. Flip is_variable on parents that have variants, clear their price
  for (const p of productRows) {
    if (variantParentIds.has(p.id)) {
      p.is_variable   = true;
      p.sale_price    = null;
      p.regular_price = null;
    }
  }

  // 7. Sanity checks
  console.log('\n📊  Pre-upload sanity check:');
  const simple   = productRows.filter(p => !p.is_variable);
  const variable = productRows.filter(p =>  p.is_variable);
  console.log(`   Products  : ${productRows.length}`);
  console.log(`     ├─ Simple   : ${simple.length}  (has own price)`);
  console.log(`     └─ Variable : ${variable.length}  (price on variants)`);
  console.log(`   Variants  : ${variantRows.length}`);

  // Warn: variable product with 0 variants
  for (const p of variable) {
    const count = variantRows.filter(v => v.product_id === p.id).length;
    if (count === 0)
      console.log(`    ⚠  id=${p.id} "${p.name.slice(0,40)}" is variable but has 0 variants!`);
  }

  // Warn: simple product with no price at all
  for (const p of simple) {
    if (p.sale_price == null && p.regular_price == null)
      console.log(`    ⚠  id=${p.id} "${p.name.slice(0,40)}" has no price`);
  }

  // Warn: variant with no price
  for (const v of variantRows) {
    if (v.sale_price == null && v.regular_price == null)
      console.log(`    ⚠  variant id=${v.id} "${v.variant_name}" has no price`);
  }

  // 8. Upload products FIRST (variants FK depends on this)
  console.log('\n📤  Uploading products …');
  let productTotal = 0;
  for (let i = 0; i < productRows.length; i += BATCH_SIZE) {
    const sent = await upsertBatch('products', productRows.slice(i, i + BATCH_SIZE));
    productTotal += sent;
    console.log(`   Batch ${Math.floor(i/BATCH_SIZE)+1}: ${sent}/${Math.min(BATCH_SIZE, productRows.length-i)} ✓`);
  }

  // 9. Upload variants AFTER products
  console.log('\n📤  Uploading variants …');
  let variantTotal = 0;
  for (let i = 0; i < variantRows.length; i += BATCH_SIZE) {
    const sent = await upsertBatch('product_variants', variantRows.slice(i, i + BATCH_SIZE));
    variantTotal += sent;
    console.log(`   Batch ${Math.floor(i/BATCH_SIZE)+1}: ${sent}/${Math.min(BATCH_SIZE, variantRows.length-i)} ✓`);
  }

  // 10. Final report
  console.log('\n🎉  Done!');
  console.log(`   ${productTotal}/${productRows.length} products upserted`);
  console.log(`   ${variantTotal}/${variantRows.length} variants upserted`);
}

main().catch(err => { console.error('Fatal:', err); process.exit(1); });