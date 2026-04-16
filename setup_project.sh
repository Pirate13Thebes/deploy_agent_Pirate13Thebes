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

# ── 3. COPY SOURCE FILES ──────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

cp "${SCRIPT_DIR}/attendance_checker.py" "${PROJECT_DIR}/attendance_checker.py"
cp "${SCRIPT_DIR}/assets.csv"            "${PROJECT_DIR}/Helpers/assets.csv"
cp "${SCRIPT_DIR}/config.json"           "${PROJECT_DIR}/Helpers/config.json"
cp "${SCRIPT_DIR}/reports.log"           "${PROJECT_DIR}/reports/reports.log"

echo "[SETUP] All project files copied."

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
