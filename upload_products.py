"""
DLab — Excel → Supabase Product Uploader
=========================================
Schema:  public.products + public.product_variants + public.categories
Products come from WooCommerce (integer IDs).

SETUP (run once in a terminal):
    pip install pandas openpyxl requests

USAGE:
    1. Fill in the CONFIG section below.
    2. Run:
         python upload_products.py

    Running it again is safe — it uses upsert (no duplicates).
"""

import re
import math
import json
import requests
import pandas as pd

# ╔══════════════════════════════════════════════════════════════╗
# ║                        CONFIG                               ║
# ╚══════════════════════════════════════════════════════════════╝

EXCEL_FILE  = r"C:\Users\Anuj Billore\Downloads\cleaned_products.xlsx"   # ← full path to your Excel file
SHEET_NAME  = 0                                   # 0 = first sheet, or "Sheet1"

SUPABASE_URL      = "https://zzqeibxwasikdmdoijfb.supabase.co"
SERVICE_ROLE_KEY  = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp6cWVpYnh3YXNpa2RtZG9pamZiIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTk5NDAxMCwiZXhwIjoyMDg3NTcwMDEwfQ._Al6n_Ai32m8p7gMXZO14xrVH5DGJTnRx0LJ1-EdPiI"  # ← Dashboard → Settings → API → service_role key
#   ↑ NEVER use anon key here. Service role key bypasses RLS so we can write products.

# ── Map YOUR Excel column headers → Supabase columns ──────────────────────
#
#   Key   = exact header text in your Excel file (case-sensitive)
#   Value = Supabase column name  (or a special value below)
#
#   Special values:
#     "_id"             → products.id  (integer, from WooCommerce / your numbering)
#     "_images"         → products.images  (comma-separated URLs → stored as text[])
#     "_category_name"  → looked up by name in public.categories → stored as category_id
#     "_variant_*"      → marks this sheet as a VARIANTS sheet (see VARIANT MODE below)
#
# ─── EXAMPLE for a simple products sheet: ──────────────────────────────────
COLUMN_MAP = {
    "ID":                "_id",               # integer product ID (from WooCommerce)
    "Name":              "name",              # required
    "Short description": "short_description",
    "Description":       "description",
    "Weight":            "weight",
    "Length":            "length",
    "Width":             "width",
    "Height":            "height",
    "Sale price":        "sale_price",        # numeric (blank = null)
    "Regular price":     "regular_price",     # numeric
    "Categories":        "_category_name",    # looked up by name → category_id integer
    "Images":            "_images",           # comma-separated URLs → stored as text[]
}
#
# ─── If you have variants in a separate sheet, set: ────────────────────────
VARIANTS_SHEET_NAME  = None   # e.g. "Variants"  — set to None if not needed
VARIANTS_COLUMN_MAP  = {
    "Variant ID":       "_id",
    "Product ID":       "product_id",         # parent product integer ID
    "Variant Name":     "variant_name",
    "Regular Price":    "regular_price",
    "Sale Price":       "sale_price",
    "Weight":           "weight",
    "Length":           "length",
    "Width":            "width",
    "Height":           "height",
    "Images":           "_images",
    "Stock Quantity":   "stock_quantity",
}

# ╔══════════════════════════════════════════════════════════════╗
# ║                      HELPERS                                ║
# ╚══════════════════════════════════════════════════════════════╝

HEADERS = {
    "apikey":        SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type":  "application/json",
    "Prefer":        "resolution=merge-duplicates,return=minimal",
}


def _safe(val):
    """Return None for NaN / empty string."""
    if val is None:
        return None
    if isinstance(val, float) and math.isnan(val):
        return None
    s = str(val).strip()
    return None if s == "" else s


def _to_float(val):
    v = _safe(val)
    if v is None:
        return None
    try:
        return float(re.sub(r"[^\d.\-]", "", v))
    except ValueError:
        return None


def _to_int(val):
    v = _to_float(val)
    return int(v) if v is not None else None


def _to_bool(val):
    v = _safe(val)
    if v is None:
        return False
    return v.strip().upper() in ("TRUE", "YES", "1", "Y")


def _to_images(val):
    v = _safe(val)
    if v is None:
        return None
    # comma or newline separated URLs → Python list → stored as Postgres text[]
    urls = [u.strip() for u in re.split(r"[,\n]", v) if u.strip()]
    return urls if urls else None


def fetch_categories() -> dict:
    """Returns {lowercase_name: id} from public.categories."""
    r = requests.get(
        f"{SUPABASE_URL}/rest/v1/categories?select=id,name",
        headers=HEADERS,
    )
    if not r.ok:
        print(f"  ✗ Could not fetch categories: {r.text}")
        return {}
    return {row["name"].lower(): row["id"] for row in r.json()}


def upsert_rows(table: str, rows: list[dict]) -> int:
    """Bulk upsert rows into a Supabase table. Returns number of rows sent."""
    if not rows:
        return 0
    r = requests.post(
        f"{SUPABASE_URL}/rest/v1/{table}",
        headers=HEADERS,
        data=json.dumps(rows),
    )
    if not r.ok:
        # Print first failure detail
        print(f"\n  ✗ Upsert error into {table}: {r.status_code} {r.text[:300]}")
        return 0
    return len(rows)


def build_product_row(excel_row: pd.Series, col_map: dict, categories: dict) -> dict | None:
    row: dict = {"is_active": True}

    for excel_col, db_col in col_map.items():
        if excel_col not in excel_row.index:
            continue
        raw = _safe(excel_row.get(excel_col))

        if db_col == "_id":
            v = _to_int(raw)
            if v is None:
                return None         # ID is required
            row["id"] = v

        elif db_col == "_category_name":
            if raw:
                cid = categories.get(raw.lower())
                if cid is None:
                    print(f"    ⚠  Category '{raw}' not found in Supabase — left as null")
                else:
                    row["category_id"] = cid

        elif db_col == "_images":
            imgs = _to_images(raw)
            if imgs:
                row["images"] = imgs

        elif db_col in ("regular_price", "sale_price", "weight", "length", "width", "height"):
            row[db_col] = _to_float(raw)

        elif db_col == "is_variable":
            row["is_variable"] = _to_bool(raw)

        elif db_col == "stock_quantity":
            row["stock_quantity"] = _to_int(raw) or 0

        else:
            row[db_col] = raw

    if "name" not in row or not row["name"]:
        return None   # skip rows without a name
    return row


# ╔══════════════════════════════════════════════════════════════╗
# ║                        MAIN                                 ║
# ╚══════════════════════════════════════════════════════════════╝

BATCH_SIZE = 50   # rows per upsert call


def upload_sheet(df: pd.DataFrame, col_map: dict, table: str, categories: dict):
    df.columns = [c.strip() for c in df.columns]
    print(f"\n  Excel columns found: {list(df.columns)}")

    rows_to_upsert: list[dict] = []
    skipped = 0

    for idx, excel_row in df.iterrows():
        row = build_product_row(excel_row, col_map, categories)
        if row is None:
            skipped += 1
            continue
        rows_to_upsert.append(row)

    # Upload in batches
    total_sent = 0
    for i in range(0, len(rows_to_upsert), BATCH_SIZE):
        batch = rows_to_upsert[i:i + BATCH_SIZE]
        sent = upsert_rows(table, batch)
        total_sent += sent
        print(f"  ↑  Batch {i // BATCH_SIZE + 1}: {sent}/{len(batch)} rows sent")

    print(f"\n  ✅ {table}: {total_sent} upserted, {skipped} skipped (no name/id)")


def main():
    if SERVICE_ROLE_KEY == "YOUR_SERVICE_ROLE_KEY_HERE":
        print("✗  Please set SERVICE_ROLE_KEY in the CONFIG section first!")
        return

    print(f"📂  Reading: {EXCEL_FILE}")
    try:
        df = pd.read_excel(EXCEL_FILE, sheet_name=SHEET_NAME, dtype=str)
    except FileNotFoundError:
        print(f"✗  File not found: {EXCEL_FILE}\n   Update EXCEL_FILE path in CONFIG.")
        return

    print(f"   {len(df)} rows loaded")

    print("\n🔍  Fetching categories from Supabase …")
    categories = fetch_categories()
    print(f"   {len(categories)} categories: {list(categories.keys())}")

    print("\n📤  Uploading products …")
    upload_sheet(df, COLUMN_MAP, "products", categories)

    # Optional: variants sheet
    if VARIANTS_SHEET_NAME:
        print(f"\n📤  Uploading variants from sheet '{VARIANTS_SHEET_NAME}' …")
        try:
            df_var = pd.read_excel(EXCEL_FILE, sheet_name=VARIANTS_SHEET_NAME, dtype=str)
            upload_sheet(df_var, VARIANTS_COLUMN_MAP, "product_variants", {})
        except Exception as e:
            print(f"  ✗  Could not read variants sheet: {e}")

    print("\n🎉  Done!")


if __name__ == "__main__":
    main()
