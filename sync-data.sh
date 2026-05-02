#!/bin/bash
# sync-data.sh
# Copies the latest Apple Health CSV files into data/, then commits and pushes.

set -e

REPO="$HOME/exercise-dashboard"
SOURCE="$HOME/Library/Mobile Documents/iCloud~com~ifunography~HealthExport/Documents/Apple Health Steps"
DEST="$REPO/data"

mkdir -p "$DEST"

echo "Syncing CSVs…"

# Monthly files (March onwards — preferred, most complete)
for f in "$SOURCE"/HealthMetrics-2026-??.csv; do
  [ -f "$f" ] && cp "$f" "$DEST/" && echo "  copied $(basename "$f")"
done

# Individual daily files for January and February
for f in "$SOURCE"/HealthMetrics-2026-01-??.csv "$SOURCE"/HealthMetrics-2026-02-??.csv; do
  [ -f "$f" ] && cp "$f" "$DEST/" && echo "  copied $(basename "$f")"
done

COUNT=$(ls "$DEST"/*.csv 2>/dev/null | wc -l | tr -d ' ')
echo ""
echo "$COUNT CSV files in data/"

# ── Git push ──────────────────────────────────────────────────────────────────
cd "$REPO"

if [ ! -d ".git" ]; then
  echo ""
  echo "No git repo found. Run these once to set up:"
  echo "  cd \"$REPO\""
  echo "  git init && git branch -M main"
  echo "  git remote add origin <your-github-repo-url>"
  echo "  git add . && git commit -m 'Initial commit' && git push -u origin main"
  exit 0
fi

# Always write a fresh sync timestamp
echo "{\"synced\":\"$(date -u '+%Y-%m-%dT%H:%M:%SZ')\"}" > "$DEST/last-sync.json"

git add data/

if git diff --cached --quiet -- data/; then
  echo ""
  echo "No changes to commit — data is already up to date."
  exit 0
fi

echo ""
echo "Committing and pushing…"
git commit -m "Update health data $(date '+%Y-%m-%d')"
git push

echo ""
echo "Done — dashboard is live."
