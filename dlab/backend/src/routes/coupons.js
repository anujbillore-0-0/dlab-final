import { Router } from 'express';
import { pool } from '../db/pool.js';

export const couponsRouter = Router();

function sqlIdent(name) {
  return `"${name.replaceAll('"', '""')}"`;
}

function resolveColumn(columns, candidates) {
  for (const candidate of candidates) {
    if (columns.has(candidate)) {
      return sqlIdent(candidate);
    }
  }
  return null;
}

async function getCouponSchema(client = pool) {
  const { rows } = await client.query(
    `
    select column_name
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'coupons'
    `,
  );

  const columns = new Set(rows.map((row) => row.column_name));

  if (columns.size === 0) {
    throw new Error('coupons table not found in public schema');
  }

  return {
    idCol: resolveColumn(columns, ['id']),
    codeCol: resolveColumn(columns, [
      'code',
      'Code',
      'coupon_code',
      'CouponCode',
      'coupon code',
      'Coupon Code',
      'promo_code',
      'PromoCode',
      'promo code',
      'Promo Code',
      'coupon',
      'Coupon',
      'name',
      'Name',
    ]),
    titleCol: resolveColumn(columns, ['title']),
    descriptionCol: resolveColumn(columns, ['description']),
    discountCol: resolveColumn(columns, [
      'discount_percentage',
      'discount',
      'Discount',
      'discount percent',
      'Discount Percent',
      'discount_percentage_%',
      'percentage',
      'Percentage',
      'percent',
      'Percent',
      'Discount percentage',
      'Discount Percentage',
    ]),
    usageCountCol: resolveColumn(columns, [
      'usage_count',
      'usage',
      'Usage',
      'used_count',
      'Used Count',
      'times_used',
      'Times Used',
      'Usage Count',
    ]),
    usageLimitCol: resolveColumn(columns, [
      'usage_limit',
      'limit',
      'Limit',
      'max_usage',
      'max_uses',
      'Usage Limit',
      'Usage/Limit',
      'usage/limit',
    ]),
    isActiveCol: resolveColumn(columns, [
      'is_active',
      'active',
      'Active',
      'status',
      'Status',
    ]),
    startsAtCol: resolveColumn(columns, ['starts_at', 'start_at']),
    expiresAtCol: resolveColumn(columns, ['expires_at', 'expiry_at', 'end_at']),
  };
}

function withPresentationFields(row) {
  const code = row.code ?? '';
  const discount = Number(row.discount_percentage ?? 0);
  const title = row.title ?? code;
  const description =
    row.description ?? `${discount}% off with code ${code}`;

  return {
    ...row,
    title,
    description,
  };
}

couponsRouter.get('/', async (_req, res, next) => {
  try {
    const schema = await getCouponSchema();

    const idExpr = schema.idCol
      ? `${schema.idCol} as id`
      : 'null::bigint as id';
    const codeExpr = schema.codeCol
      ? `${schema.codeCol} as code`
      : schema.idCol
        ? `('CPN' || ${schema.idCol}::text) as code`
        : `'COUPON'::text as code`;
    const titleExpr = schema.titleCol
      ? `${schema.titleCol} as title`
      : 'null::text as title';
    const descriptionExpr = schema.descriptionCol
      ? `${schema.descriptionCol} as description`
      : 'null::text as description';
    const discountExpr = schema.discountCol
      ? `${schema.discountCol}::numeric as discount_percentage`
      : '0::numeric as discount_percentage';
    const usageCountExpr = schema.usageCountCol
      ? `${schema.usageCountCol}::integer as usage_count`
      : '0::integer as usage_count';
    const usageLimitExpr = schema.usageLimitCol
      ? `${schema.usageLimitCol}::integer as usage_limit`
      : '1::integer as usage_limit';
    const remainingExpr =
      schema.usageCountCol && schema.usageLimitCol
        ? `greatest(${schema.usageLimitCol}::integer - ${schema.usageCountCol}::integer, 0) as remaining_uses`
        : schema.usageLimitCol
          ? `${schema.usageLimitCol}::integer as remaining_uses`
          : '1::integer as remaining_uses';
    const startsAtExpr = schema.startsAtCol
      ? `${schema.startsAtCol} as starts_at`
      : 'null::timestamptz as starts_at';
    const expiresAtExpr = schema.expiresAtCol
      ? `${schema.expiresAtCol} as expires_at`
      : 'null::timestamptz as expires_at';

    const where = ['1=1'];
    if (schema.isActiveCol) {
      where.push(`${schema.isActiveCol} = true`);
    }
    if (schema.startsAtCol) {
      where.push(`(${schema.startsAtCol} is null or ${schema.startsAtCol} <= now())`);
    }
    if (schema.expiresAtCol) {
      where.push(`(${schema.expiresAtCol} is null or ${schema.expiresAtCol} > now())`);
    }
    if (schema.usageCountCol && schema.usageLimitCol) {
      where.push(`${schema.usageCountCol} < ${schema.usageLimitCol}`);
    }

    const orderBySecondary = schema.codeCol
      ? `upper(${schema.codeCol}) asc`
      : schema.idCol
        ? `${schema.idCol} asc`
        : '1';
    const orderBy = schema.discountCol
      ? `coalesce(${schema.discountCol}, 0) desc, ${orderBySecondary}`
      : orderBySecondary;

    const { rows } = await pool.query(
      `
      select
        ${idExpr},
        ${codeExpr},
        ${titleExpr},
        ${descriptionExpr},
        ${discountExpr},
        ${usageCountExpr},
        ${usageLimitExpr},
        ${remainingExpr},
        ${startsAtExpr},
        ${expiresAtExpr}
      from public.coupons
      where ${where.join(' and ')}
      order by ${orderBy}
      `,
    );

    return res.json({ coupons: rows.map(withPresentationFields) });
  } catch (err) {
    return next(err);
  }
});

couponsRouter.post('/apply', async (req, res, next) => {
  const code = (req.body?.code ?? '').toString().trim().toUpperCase();

  if (!code) {
    return res.status(400).json({ message: 'Coupon code is required' });
  }

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const schema = await getCouponSchema(client);

    const idExpr = schema.idCol
      ? `${schema.idCol} as id`
      : 'null::bigint as id';
    const codeExpr = schema.codeCol
      ? `${schema.codeCol} as code`
      : schema.idCol
        ? `('CPN' || ${schema.idCol}::text) as code`
        : `'COUPON'::text as code`;
    const titleExpr = schema.titleCol
      ? `${schema.titleCol} as title`
      : 'null::text as title';
    const descriptionExpr = schema.descriptionCol
      ? `${schema.descriptionCol} as description`
      : 'null::text as description';
    const discountExpr = schema.discountCol
      ? `${schema.discountCol}::numeric as discount_percentage`
      : '0::numeric as discount_percentage';
    const usageCountExpr = schema.usageCountCol
      ? `${schema.usageCountCol}::integer as usage_count`
      : '0::integer as usage_count';
    const usageLimitExpr = schema.usageLimitCol
      ? `${schema.usageLimitCol}::integer as usage_limit`
      : '1::integer as usage_limit';
    const isActiveExpr = schema.isActiveCol
      ? `${schema.isActiveCol} as is_active`
      : 'true as is_active';
    const startsAtExpr = schema.startsAtCol
      ? `${schema.startsAtCol} as starts_at`
      : 'null::timestamptz as starts_at';
    const expiresAtExpr = schema.expiresAtCol
      ? `${schema.expiresAtCol} as expires_at`
      : 'null::timestamptz as expires_at';

    let lookupClause = '';
    let lookupValue = null;

    if (schema.codeCol) {
      lookupClause = `upper(${schema.codeCol}) = $1`;
      lookupValue = code;
    } else if (schema.idCol) {
      const idMatch = /^CPN(\d+)$/i.exec(code);
      if (!idMatch) {
        await client.query('ROLLBACK');
        return res.status(400).json({
          message: 'Coupon code format is invalid for current schema',
        });
      }
      lookupClause = `${schema.idCol} = $1`;
      lookupValue = Number(idMatch[1]);
    } else {
      await client.query('ROLLBACK');
      return res.status(500).json({
        message: 'Coupons table is missing lookup columns (code/id)',
      });
    }

    const couponResult = await client.query(
      `
      select
        ${idExpr},
        ${codeExpr},
        ${titleExpr},
        ${descriptionExpr},
        ${discountExpr},
        ${usageCountExpr},
        ${usageLimitExpr},
        ${isActiveExpr},
        ${startsAtExpr},
        ${expiresAtExpr}
      from public.coupons
      where ${lookupClause}
      for update
      `,
      [lookupValue],
    );

    if (couponResult.rowCount === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ message: 'Coupon not found' });
    }

    const coupon = couponResult.rows[0];
    const now = new Date();

    const notStarted = coupon.starts_at && new Date(coupon.starts_at) > now;
    const expired = coupon.expires_at && new Date(coupon.expires_at) <= now;
    const hasUsageTracking = Boolean(schema.usageCountCol && schema.usageLimitCol);
    const limitReached =
      hasUsageTracking
        ? Number(coupon.usage_count) >= Number(coupon.usage_limit)
        : false;
    const inactive = coupon.is_active !== true;

    if (notStarted || expired || limitReached || inactive) {
      if ((limitReached || expired) && schema.isActiveCol && coupon.id != null) {
        await client.query(
          `
          update public.coupons
          set ${schema.isActiveCol} = false
          where ${schema.idCol ?? 'id'} = $1
          `,
          [coupon.id],
        );
      }

      await client.query('COMMIT');

      return res.status(410).json({
        message: 'Coupon is expired or no longer valid',
        code: coupon.code,
      });
    }

    let updatedCoupon = coupon;

    if (schema.idCol && coupon.id != null && schema.usageCountCol) {
      const setClauses = [`${schema.usageCountCol} = ${schema.usageCountCol} + 1`];
      if (schema.isActiveCol && schema.usageLimitCol) {
        setClauses.push(
          `${schema.isActiveCol} = case when ${schema.usageCountCol} + 1 >= ${schema.usageLimitCol} then false else ${schema.isActiveCol} end`,
        );
      }

      const remainingExpr = schema.usageLimitCol
        ? `greatest(${schema.usageLimitCol}::integer - ${schema.usageCountCol}::integer, 0) as remaining_uses`
        : '0::integer as remaining_uses';

      const updateResult = await client.query(
        `
        update public.coupons
        set ${setClauses.join(', ')}
        where ${schema.idCol} = $1
        returning
          ${idExpr},
          ${codeExpr},
          ${titleExpr},
          ${descriptionExpr},
          ${discountExpr},
          ${usageCountExpr},
          ${usageLimitExpr},
          ${remainingExpr},
          ${isActiveExpr},
          ${startsAtExpr},
          ${expiresAtExpr}
        `,
        [coupon.id],
      );

      if (updateResult.rowCount > 0) {
        updatedCoupon = updateResult.rows[0];
      }
    }

    await client.query('COMMIT');

    return res.json({
      message: 'Coupon applied successfully',
      coupon: withPresentationFields(updatedCoupon),
    });
  } catch (err) {
    await client.query('ROLLBACK');
    return next(err);
  } finally {
    client.release();
  }
});
