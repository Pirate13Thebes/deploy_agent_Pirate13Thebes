#!/bin/bash

# ─────────────────────────────────────────────
#  setup_project.sh — Automated Project Bootstrapper
#  Student Attendance Tracker — Chrys Elisée Gnagne
# ─────────────────────────────────────────────

# ── SIGNAL TRAP ──────────────────────────────
trap_handler() {
    echo ""
    echo "[INTERRUPTED] Ctrl+C detected. Cleaning up..."

    if [ -n "$PROJECT_DIR" ] && [ -d "$PROJECT_DIR" ]; then
        ARCHIVE_NAME="attendance_tracker_${INPUT}_archive"
        tar -czf "${ARCHIVE_NAME}.tar.gz" "$PROJECT_DIR"
        echo "[TRAP] Project bundled into: ${ARCHIVE_NAME}.tar.gz"
        rm -rf "$PROJECT_DIR"
        echo "[TRAP] Incomplete directory '${PROJECT_DIR}' removed."
    fi

    echo "[TRAP] Exiting gracefully."
    exit 1
}

trap trap_handler SIGINT

# ── 1. GET USER INPUT ─────────────────────────
echo "========================================"
echo "  Attendance Tracker — Project Factory  "
echo "========================================"
echo ""
read -p "Enter a project name (e.g. v1): " INPUT

if [ -z "$INPUT" ]; then
    echo "[ERROR] Project name cannot be empty."
    exit 1
fi

PROJECT_DIR="attendance_tracker_${INPUT}"

if [ -d "$PROJECT_DIR" ]; then
    echo "[ERROR] Directory '${PROJECT_DIR}' already exists. Choose a different name."
    exit 1
fi

echo ""
echo "[SETUP] Creating project: ${PROJECT_DIR}"

# ── 2. CREATE DIRECTORY STRUCTURE ────────────
mkdir -p "${PROJECT_DIR}/Helpers"
mkdir -p "${PROJECT_DIR}/reports"

echo "[SETUP] Directory structure created."

# ── 3. GENERATE FILES ─────────────────────────

# attendance_checker.py
cat > "${PROJECT_DIR}/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PYEOF

# assets.csv
cat > "${PROJECT_DIR}/Helpers/assets.csv" << 'CSVEOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF

# config.json (defaults)
cat > "${PROJECT_DIR}/Helpers/config.json" << 'JSONEOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
JSONEOF

# reports.log (initial placeholder)
cat > "${PROJECT_DIR}/reports/reports.log" << 'LOGEOF'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOGEOF

echo "[SETUP] All project files generated."

# ── 4. DYNAMIC CONFIGURATION (sed) ───────────
echo ""
echo "----------------------------------------"
echo "  Threshold Configuration"
echo "  Current defaults → Warning: 75%  |  Failure: 50%"
echo "----------------------------------------"
read -p "Do you want to update the attendance thresholds? (y/n): " UPDATE_THRESH

if [[ "$UPDATE_THRESH" == "y" || "$UPDATE_THRESH" == "Y" ]]; then

    read -p "Enter new Warning threshold (default 75): " WARN_VAL
    read -p "Enter new Failure threshold (default 50): " FAIL_VAL

    # Use defaults if user left blank
    WARN_VAL=${WARN_VAL:-75}
    FAIL_VAL=${FAIL_VAL:-50}

    # Validate numeric input
    if ! [[ "$WARN_VAL" =~ ^[0-9]+$ ]] || ! [[ "$FAIL_VAL" =~ ^[0-9]+$ ]]; then
        echo "[ERROR] Thresholds must be integers. Keeping defaults."
    elif [ "$FAIL_VAL" -ge "$WARN_VAL" ]; then
        echo "[ERROR] Failure threshold must be lower than Warning threshold. Keeping defaults."
    else
        # sed in-place edit on config.json
        sed -i "s/\"warning\": [0-9]*/\"warning\": ${WARN_VAL}/" "${PROJECT_DIR}/Helpers/config.json"
        sed -i "s/\"failure\": [0-9]*/\"failure\": ${FAIL_VAL}/" "${PROJECT_DIR}/Helpers/config.json"
        echo "[CONFIG] Thresholds updated → Warning: ${WARN_VAL}%  |  Failure: ${FAIL_VAL}%"
    fi

else
    echo "[CONFIG] Keeping default thresholds."
fi

# ── 5. HEALTH CHECK ───────────────────────────
echo ""
echo "----------------------------------------"
echo "  Environment Health Check"
echo "----------------------------------------"

# Check python3
if python3 --version &>/dev/null; then
    PY_VERSION=$(python3 --version)
    echo "[OK] Python3 found: ${PY_VERSION}"
else
    echo "[WARNING] python3 is not installed. The attendance checker will not run."
fi

# Verify directory structure
echo ""
echo "[CHECK] Verifying project structure..."
MISSING=0

for path in \
    "${PROJECT_DIR}/attendance_checker.py" \
    "${PROJECT_DIR}/Helpers/assets.csv" \
    "${PROJECT_DIR}/Helpers/config.json" \
    "${PROJECT_DIR}/reports/reports.log"
do
    if [ -f "$path" ]; then
        echo "  [OK] $path"
    else
        echo "  [MISSING] $path"
        MISSING=$((MISSING + 1))
    fi
done

if [ "$MISSING" -gt 0 ]; then
    echo ""
    echo "[WARNING] ${MISSING} file(s) missing from the project structure."
else
    echo ""
    echo "[OK] All files are in place."
fi

# ── DONE ──────────────────────────────────────
echo ""
echo "========================================"
echo "  Project '${PROJECT_DIR}' is ready!"
echo "  To run: cd ${PROJECT_DIR} && python3 attendance_checker.py"
echo "========================================"
