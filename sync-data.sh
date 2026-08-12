#!/bin/bash
# sync-data.sh
# Merges the latest Apple Health CSV files into data/, then commits and pushes.
# Monthly files are merged (new rows added, existing rows updated) rather than
# replaced, so partial re-exports from the Auto Export app can't wipe history.

set -e

REPO="$HOME/exercise-dashboard"
SOURCE="$HOME/Library/Mobile Documents/iCloud~com~ifunography~HealthExport/Documents/Apple Health Steps"
DEST="$REPO/data"

mkdir -p "$DEST"

# Merge a source CSV into the destination, keeping the best data for each date.
# "Best" = the source row wins if it has more non-empty metric columns than what
# we already have; otherwise we keep the existing row.
merge_csv() {
  local src="$1" dst="$2"
  [ -f "$src" ] || return
  if [ ! -f "$dst" ]; then
    cp "$src" "$dst"
    return
  fi
  python3 - "$src" "$dst" <<'PYEOF'
import sys, csv, io

def non_empty(row):
    return sum(1 for k, v in row.items() if k != 'Date/Time' and v.strip())

src_path, dst_path = sys.argv[1], sys.argv[2]

with open(src_path, newline='') as f:
    src_rows = {r['Date/Time']: r for r in csv.DictReader(f)}
with open(dst_path, newline='') as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    dst_rows = {r['Date/Time']: r for r in reader}

merged = dict(dst_rows)
for dt, row in src_rows.items():
    if dt not in merged or non_empty(row) >= non_empty(merged[dt]):
        merged[dt] = row

out = io.StringIO()
w = csv.DictWriter(out, fieldnames=fieldnames, lineterminator='\n')
w.writeheader()
for dt in sorted(merged):
    w.writerow(merged[dt])

with open(dst_path, 'w') as f:
    f.write(out.getvalue())
PYEOF
}

echo "Syncing CSVs…"

# Monthly summary files: merge current month, skip past months (locked in git)
CURRENT_MM=$(date '+%m')
for f in "$SOURCE"/HealthMetrics-2026-??.csv; do
  [ -f "$f" ] || continue
  MM=$(basename "$f" | sed 's/HealthMetrics-2026-\(..\)\.csv/\1/')
  if [ "$MM" = "$CURRENT_MM" ]; then
    DEST_FILE="$DEST/$(basename "$f")"
    merge_csv "$f" "$DEST_FILE" && echo "  merged $(basename "$f")"
  fi
done

# Daily files for all months: copy if missing (daily files are immutable once written)
for f in "$SOURCE"/HealthMetrics-2026-??-??.csv; do
  [ -f "$f" ] || continue
  DEST_FILE="$DEST/$(basename "$f")"
  [ -f "$DEST_FILE" ] || { cp "$f" "$DEST_FILE" && echo "  copied $(basename "$f")"; }
done

COUNT=$(ls "$DEST"/*.csv 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "$COUNT CSV files in data/"

# ── Git push ──────────────────────────────────────────────────────────────────
cd "$REPO"

# Check if health CSVs changed
git add data/*.csv 2>/dev/null || true

if git diff --cached --quiet; then
  echo ""
  echo "No changes to commit — data is already up to date."
  exit 0
fi

# CSVs changed — write timestamp and stage everything
echo "{\"synced\":\"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\"}" > "$DEST/last-sync.json"
git add data/

echo ""
echo "Committing and pushing…"
git commit -m "Update health data $(date '+%Y-%m-%d')"
git push

echo ""
echo "Done — dashboard is live."
