/**
 * WooCommerce Webhook Receiver
 *
 * Registers webhooks in WooCommerce → Settings → Advanced → Webhooks:
 *   Topic              Delivery URL
 *   ─────────────────  ────────────────────────────────
 *   product.created    https://app.dezign-lab.com:3000/api/webhooks/product
 *   product.updated    https://app.dezign-lab.com:3000/api/webhooks/product
 *   product.deleted    https://app.dezign-lab.com:3000/api/webhooks/product
 *
 * Required env vars:
 *   SUPABASE_URL              — Supabase project URL
 *   SUPABASE_SERVICE_ROLE_KEY — service-role key (bypasses RLS)
 *   WOO_WEBHOOK_SECRET        — the secret set in WooCommerce webhook settings
 */

import crypto from 'crypto';
import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';

export const webhookRouter = Router();

// ── Supabase Admin client ──────────────────────────────────────────────────
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  { auth: { autoRefreshToken: false, persistSession: false } },
);

// ── HMAC verification ──────────────────────────────────────────────────────
function verifyWooSignature(req) {
  const secret = process.env.WOO_WEBHOOK_SECRET;
  if (!secret) {
    console.warn('[webhook] WOO_WEBHOOK_SECRET not set — skipping verification');
    return true; // allow in local dev; tighten for production
  }

  const signature = req.headers['x-wc-webhook-signature'];
  if (!signature) return false;

  const hmac = crypto
    .createHmac('sha256', secret)
    .update(req.rawBody)
    .digest('base64');

  return crypto.timingSafeEqual(Buffer.from(hmac), Buffer.from(signature));
}

// ── Status mapping ─────────────────────────────────────────────────────────
// WooCommerce publish status → product_status_enum in Supabase
function mapStatus(wooStatus, stockStatus) {
  if (wooStatus === 'trash') return 'archived';
  if (wooStatus !== 'publish') return 'inactive';
  if (stockStatus === 'outofstock') return 'out_of_stock';
  return 'active';
}

// ── Resolve category UUID by WooCommerce category slug/name ───────────────
// Returns first matched category UUID, or null if none found.
async function resolveCategoryId(wooCategories = []) {
  if (!wooCategories.length) return null;

  for (const cat of wooCategories) {
    const slug = cat.slug ?? '';
    const name = cat.name ?? '';

    // Try slug first (more reliable), then name
    const { data: bySlug } = await supabase
      .from('categories')
      .select('id')
      .eq('slug', slug)
      .maybeSingle();

    if (bySlug) return bySlug.id;

    if (name) {
      const { data: byName } = await supabase
        .from('categories')
        .select('id')
        .ilike('name', name)
        .maybeSingle();

      if (byName) return byName.id;
    }
  }

  return null;
}

// ── POST /api/webhooks/product ─────────────────────────────────────────────
// Handles product.created, product.updated, product.deleted
webhookRouter.post('/product', async (req, res) => {
  // 1. Verify signature
  if (!verifyWooSignature(req)) {
    console.warn('[webhook/product] Invalid signature — request rejected');
    return res.status(401).json({ message: 'Invalid webhook signature' });
  }

  const topic = req.headers['x-wc-webhook-topic'] ?? '';
  const payload = req.body;

  console.log(`[webhook/product] Received topic: ${topic}, product id: ${payload?.id}`);

  try {
    // 2. Handle deletion
    if (topic === 'product.deleted') {
      const slug = payload?.slug;
      if (!slug) return res.status(400).json({ message: 'Missing slug in deleted payload' });

      const { error } = await supabase
        .from('products')
        .update({ status: 'archived', updated_at: new Date().toISOString() })
        .eq('slug', slug);

      if (error) throw error;

      console.log(`[webhook/product] Soft-deleted (archived): ${slug}`);
      return res.json({ ok: true, action: 'archived', slug });
    }

    // 3. Map fields for upsert (created / updated)
    const slug = payload?.slug;
    if (!slug) return res.status(400).json({ message: 'Missing slug in payload' });

    const categoryId = await resolveCategoryId(payload.categories ?? []);

    // WooCommerce prices are strings; coerce to float
    const basePrice    = parseFloat(payload.regular_price || payload.price || '0') || 0;
    const salePrice    = parseFloat(payload.sale_price || '') || null;
    const stockQty     = Number(payload.stock_quantity ?? 0);

    const productRow = {
      name:             payload.name        ?? '',
      slug,
      description:      payload.description ?? '',
      sku:              payload.sku         ?? null,
      base_price:       basePrice,
      discount_price:   salePrice,
      stock_quantity:   stockQty,
      status:           mapStatus(payload.status, payload.stock_status),
      meta_title:       payload.name        ?? null,
      meta_description: payload.short_description ?? null,
      updated_at:       new Date().toISOString(),
      ...(categoryId ? { category_id: categoryId } : {}),
    };

    // Upsert on slug (unique key)
    const { data: upserted, error: upsertError } = await supabase
      .from('products')
      .upsert(productRow, { onConflict: 'slug', returning: 'minimal' });

    if (upsertError) throw upsertError;

    // 4. Sync primary image (if any)
    const images = payload.images ?? [];
    if (images.length) {
      // Fetch the product UUID we just upserted
      const { data: prod } = await supabase
        .from('products')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();

      if (prod) {
        // Replace all images for this product
        await supabase.from('product_images').delete().eq('product_id', prod.id);

        const imageRows = images.map((img, idx) => ({
          product_id: prod.id,
          image_url:  img.src,
          alt_text:   img.alt || img.name || null,
          is_primary: idx === 0,
          sort_order: idx,
        }));

        const { error: imgError } = await supabase
          .from('product_images')
          .insert(imageRows);

        if (imgError) {
          // Non-fatal — log but don't fail the webhook
          console.error('[webhook/product] Image sync error:', imgError.message);
        }
      }
    }

    console.log(`[webhook/product] Upserted: ${slug}`);
    return res.json({ ok: true, action: topic, slug });
  } catch (err) {
    console.error('[webhook/product] Error:', err.message);
    // Return 200 so WooCommerce doesn't retry infinitely on permanent errors;
    // for transient errors (DB down) return 500 to trigger retry.
    const status = err?.code === 'PGRST' ? 500 : 200;
    return res.status(status).json({ ok: false, error: err.message });
  }
});
