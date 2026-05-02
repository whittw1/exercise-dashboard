# 2026 Health Dashboard

A static GitHub Pages site showing YTD step count, active calories, and stand hours from Apple Health exports.

## Setup (one time)

1. **Create a new GitHub repo** at github.com — name it whatever you like (e.g. `health-dashboard`).

2. **Clone it locally:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/health-dashboard.git
   cd health-dashboard
   ```

3. **Copy these files into it:**
   ```bash
   cp /path/to/github-health-dashboard/* .
   ```

4. **Run the sync script** to pull in your CSV data:
   ```bash
   chmod +x sync-data.sh
   ./sync-data.sh
   ```

5. **Push everything:**
   ```bash
   git add .
   git commit -m "Initial health dashboard"
   git push
   ```

6. **Enable GitHub Pages:**
   - Go to your repo on github.com → Settings → Pages
   - Source: **Deploy from a branch**
   - Branch: `main`, folder: `/ (root)`
   - Save. Your page will be live at `https://YOUR_USERNAME.github.io/health-dashboard/` in ~60 seconds.

## Updating the data

Whenever you want to refresh the numbers, run:

```bash
./sync-data.sh
git add data/ && git commit -m "Update health data $(date +%Y-%m-%d)" && git push
```

The page will update automatically after the push.

## Repo structure

```
index.html        ← the dashboard page
sync-data.sh      ← script to copy latest CSVs from your Apple Health export
data/
  HealthMetrics-2026-03.csv     ← monthly files (Mar+)
  HealthMetrics-2026-04.csv
  HealthMetrics-2026-05.csv
  HealthMetrics-2026-01-01.csv  ← daily files (Jan + Feb)
  HealthMetrics-2026-01-02.csv
  ...
```
